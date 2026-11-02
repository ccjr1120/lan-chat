// 从 assets/web/index.html 的 mascot 脚本块（mascot:begin … mascot:end）生成各平台应用图标，
// 保证图标与网页端 / App 绘制同源（Flutter 端 lib/ui/widgets/mascot_painter.dart 为逐行移植）。
//
// 运行方式（不往项目里安装 node 依赖，canvas 模块从外部路径只读加载）：
//   CANVAS_MODULE=/path/to/node_modules/@napi-rs/canvas node tool/mascot/render_icons.mjs
//
// 输出（文件名不变，Contents.json 不改）：
// - Android mipmap-*/ic_launcher.png：猫脸 + 圆角底板，透明背景；
// - iOS AppIcon.appiconset：满版不透明（belly 底色 + 猫脸，不画底板，由系统裁圆角），RGB 无 alpha；
// - macOS AppIcon.appiconset：约 10% 透明边距，内部为底板 + 猫脸；
// - Windows runner/resources/app_icon.ico：与 Android 相同样式，16–256px 多尺寸 PNG 条目。
// 每个尺寸按真实像素绘制，小于 64px 时使用 mini 细节。
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { deflateSync } from 'node:zlib';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const modulePath = process.env.CANVAS_MODULE;
if (!modulePath) {
  console.error('CANVAS_MODULE is required (path to @napi-rs/canvas).');
  process.exit(1);
}
const { createCanvas } = createRequire(import.meta.url)(resolve(modulePath));

// ---------------------------------------------------------------- 加载绘制代码
function loadMascot() {
  const html = readFileSync(join(ROOT, 'assets/web/index.html'), 'utf8');
  const begin = html.indexOf('/* mascot:begin */');
  const end = html.indexOf('/* mascot:end */');
  if (begin < 0 || end < begin) throw new Error('mascot block not found in index.html');
  const src = html.slice(begin, end);
  // eslint-disable-next-line no-new-func
  return new Function(`${src}\nreturn { PALETTES: PALETTES, drawCat: drawCat, roundRectPath: roundRectPath };`)();
}
const { PALETTES, drawCat } = loadMascot();

// ---------------------------------------------------------------- PNG 编码
const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

// rgba：canvas getImageData 的非预乘 RGBA；alpha=false 时输出 RGB（color type 2）。
function encodePng(width, height, rgba, alpha) {
  const channels = alpha ? 4 : 3;
  const raw = Buffer.alloc((width * channels + 1) * height);
  let o = 0;
  for (let y = 0; y < height; y++) {
    raw[o++] = 0;
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
      if (alpha) raw[o++] = rgba[i + 3];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = alpha ? 6 : 2;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// ---------------------------------------------------------------- 绘制
const P = PALETTES.light;

// kind: 'plate'（Android 圆角底板、透明背景）| 'full'（iOS 满版不透明）| 'mac'（10% 边距 + 底板）
function render(px, kind) {
  const canvas = createCanvas(px, px);
  const ctx = canvas.getContext('2d');
  const detail = px < 64 ? 'mini' : 'full';
  if (kind === 'full') {
    ctx.fillStyle = P.belly;
    ctx.fillRect(0, 0, px, px);
    // 无底板时 drawFace 使用较大的 36 半径头部；缩到 0.86 留出耳朵与系统圆角的余量。
    drawCat(ctx, { palette: 'light', detail, pose: 'face', plate: false, x: px / 2, y: px / 2, size: px * 0.86 });
  } else if (kind === 'mac') {
    const inner = Math.round(px * 0.8);
    drawCat(ctx, { palette: 'light', detail, pose: 'face', plate: true, x: px / 2, y: px / 2, size: inner });
  } else {
    drawCat(ctx, { palette: 'light', detail, pose: 'face', plate: true, x: px / 2, y: px / 2, size: px });
  }
  const { data } = ctx.getImageData(0, 0, px, px);
  return encodePng(px, px, data, kind !== 'full');
}

function write(rel, px, kind) {
  writeFileSync(join(ROOT, rel), render(px, kind));
  console.log('wrote', rel, `${px}x${px}`);
}

// Android
for (const [dir, px] of [['mdpi', 48], ['hdpi', 72], ['xhdpi', 96], ['xxhdpi', 144], ['xxxhdpi', 192]]) {
  write(`android/app/src/main/res/mipmap-${dir}/ic_launcher.png`, px, 'plate');
}

// iOS：按 Contents.json 计算像素尺寸。
const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const iosImages = JSON.parse(readFileSync(join(ROOT, iosDir, 'Contents.json'), 'utf8')).images;
const iosDone = new Set();
for (const image of iosImages) {
  if (!image.filename || iosDone.has(image.filename)) continue;
  iosDone.add(image.filename);
  const px = Math.round(parseFloat(image.size) * parseFloat(image.scale));
  write(`${iosDir}/${image.filename}`, px, 'full');
}

// macOS
const macDir = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';
for (const px of [16, 32, 64, 128, 256, 512, 1024]) {
  write(`${macDir}/app_icon_${px}.png`, px, 'mac');
}

// Windows：多尺寸 PNG 封装为 ICO（Vista+ 支持 PNG 条目），与 Android 同为圆角底板、透明背景。
function encodeIco(pngs) {
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0);
  header.writeUInt16LE(1, 2);
  header.writeUInt16LE(pngs.length, 4);
  const entries = [];
  let offset = 6 + 16 * pngs.length;
  for (const { px, png } of pngs) {
    const e = Buffer.alloc(16);
    e[0] = px >= 256 ? 0 : px;
    e[1] = px >= 256 ? 0 : px;
    e.writeUInt16LE(1, 4);
    e.writeUInt16LE(32, 6);
    e.writeUInt32LE(png.length, 8);
    e.writeUInt32LE(offset, 12);
    offset += png.length;
    entries.push(e);
  }
  return Buffer.concat([header, ...entries, ...pngs.map((p) => p.png)]);
}
const winIcon = 'windows/runner/resources/app_icon.ico';
const winSizes = [16, 24, 32, 48, 64, 128, 256];
writeFileSync(join(ROOT, winIcon), encodeIco(winSizes.map((px) => ({ px, png: render(px, 'plate') }))));
console.log('wrote', winIcon, winSizes.join('/'));
