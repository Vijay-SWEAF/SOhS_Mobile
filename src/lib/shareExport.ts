import { Directory, Filesystem } from "@capacitor/filesystem";
import { Capacitor } from "@capacitor/core";
import { Share } from "@capacitor/share";
import type { DailyQuestion, OptionIndex } from "./questions";
import { FAINT, GOLD, HAIRLINE, INK, INK_2, MUTED, PAPER, TEAL } from "./theme";
import { getShareBadge } from "./shareBadge";
import sohsAppIconUrl from "../assets/sohs-app-icon.png";

interface ShareExportOptions {
  question: DailyQuestion;
  choice: OptionIndex;
  accent: string;
  isMajority: boolean;
}

const WIDTH = 1080;
const HEIGHT = 1350;
const PAD = 88;

function roundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, width: number, height: number, radius: number) {
  ctx.beginPath();
  ctx.moveTo(x + radius, y);
  ctx.lineTo(x + width - radius, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
  ctx.lineTo(x + width, y + height - radius);
  ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
  ctx.lineTo(x + radius, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
  ctx.lineTo(x, y + radius);
  ctx.quadraticCurveTo(x, y, x + radius, y);
  ctx.closePath();
}

function wrapText(ctx: CanvasRenderingContext2D, text: string, maxWidth: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let line = "";

  for (const word of words) {
    const next = line ? `${line} ${word}` : word;
    if (ctx.measureText(next).width <= maxWidth || !line) {
      line = next;
    } else {
      lines.push(line);
      line = word;
    }
  }

  if (line) lines.push(line);
  return lines;
}

function drawWrappedText(
  ctx: CanvasRenderingContext2D,
  text: string,
  x: number,
  y: number,
  maxWidth: number,
  lineHeight: number,
): number {
  const lines = wrapText(ctx, text, maxWidth);
  lines.forEach((line, i) => ctx.fillText(line, x, y + i * lineHeight));
  return y + lines.length * lineHeight;
}

function dataUrlToBase64(dataUrl: string): string {
  const marker = "base64,";
  const index = dataUrl.indexOf(marker);
  if (index === -1) throw new Error("Unable to export PNG.");
  return dataUrl.slice(index + marker.length);
}

function dataUrlToBlob(dataUrl: string): Blob {
  const base64 = dataUrlToBase64(dataUrl);
  const bytes = Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
  return new Blob([bytes], { type: "image/png" });
}

function downloadDataUrl(dataUrl: string, fileName: string): void {
  const link = document.createElement("a");
  link.href = dataUrl;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("Unable to load share image asset."));
    image.src = src;
  });
}

function drawRoundImage(
  ctx: CanvasRenderingContext2D,
  image: HTMLImageElement,
  x: number,
  y: number,
  size: number,
): void {
  ctx.save();
  ctx.beginPath();
  ctx.arc(x + size / 2, y + size / 2, size / 2, 0, Math.PI * 2);
  ctx.clip();
  ctx.drawImage(image, x, y, size, size);
  ctx.restore();

  ctx.beginPath();
  ctx.arc(x + size / 2, y + size / 2, size / 2 - 1, 0, Math.PI * 2);
  ctx.strokeStyle = `${GOLD}88`;
  ctx.lineWidth = 3;
  ctx.stroke();
}

export async function renderSharePngDataUrl({
  question,
  choice,
  accent,
  isMajority,
}: ShareExportOptions): Promise<string> {
  const [appIcon] = await Promise.all([loadImage(sohsAppIconUrl), document.fonts.ready]);

  const canvas = document.createElement("canvas");
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas is not available.");

  const bg = ctx.createLinearGradient(0, 0, WIDTH, HEIGHT);
  bg.addColorStop(0, INK_2);
  bg.addColorStop(0.62, INK);
  ctx.fillStyle = bg;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  const glow = ctx.createRadialGradient(WIDTH * 0.5, HEIGHT * 0.76, 0, WIDTH * 0.5, HEIGHT * 0.76, 520);
  glow.addColorStop(0, `${accent}22`);
  glow.addColorStop(1, "rgba(11,16,32,0)");
  ctx.fillStyle = glow;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);

  roundedRect(ctx, 34, 34, WIDTH - 68, HEIGHT - 68, 42);
  ctx.strokeStyle = `${GOLD}66`;
  ctx.lineWidth = 2;
  ctx.stroke();

  ctx.fillStyle = GOLD;
  ctx.font = "700 27px Inter, system-ui, sans-serif";
  ctx.letterSpacing = "8px";
  ctx.fillText(`SOhS · ${question.kind} · DAY ${question.day}`, PAD, 112);
  ctx.letterSpacing = "0px";

  ctx.fillStyle = PAPER;
  ctx.font = "400 62px Fraunces, Georgia, serif";
  let y = drawWrappedText(ctx, question.text, PAD, 220, WIDTH - PAD * 2, 78);

  const chosen = question.options[choice];
  const badge = getShareBadge(chosen.pct, isMajority);
  const badgeY = Math.max(y + 90, 560);
  const badgeHeight = 190;
  roundedRect(ctx, PAD, badgeY, WIDTH - PAD * 2, badgeHeight, 24);
  ctx.fillStyle = "rgba(255,255,255,0.035)";
  ctx.fill();
  ctx.strokeStyle = HAIRLINE;
  ctx.lineWidth = 2;
  ctx.stroke();

  ctx.fillStyle = accent;
  ctx.font = "700 24px Inter, system-ui, sans-serif";
  ctx.letterSpacing = "6px";
  ctx.fillText(badge.eyebrow, PAD + 34, badgeY + 52);
  ctx.letterSpacing = "0px";

  ctx.fillStyle = MUTED;
  ctx.font = "700 25px Inter, system-ui, sans-serif";
  ctx.textAlign = "right";
  ctx.fillText(chosen.label.toUpperCase(), WIDTH - PAD - 34, badgeY + 52);
  ctx.textAlign = "left";

  ctx.fillStyle = PAPER;
  ctx.font = "400 46px Fraunces, Georgia, serif";
  ctx.fillText(badge.title, PAD + 34, badgeY + 118);

  ctx.fillStyle = MUTED;
  ctx.font = "500 29px Inter, system-ui, sans-serif";
  ctx.fillText(badge.detail, PAD + 34, badgeY + 160);

  const shareLine = isMajority ? `With the ${chosen.pct}%.` : `The rarer ${chosen.pct}%.`;
  ctx.fillStyle = accent;
  ctx.font = "500 92px Fraunces, Georgia, serif";
  y = Math.max(badgeY + badgeHeight + 110, 820);
  drawWrappedText(ctx, shareLine, PAD, y, WIDTH - PAD * 2, 100);

  const barY = 1080;
  roundedRect(ctx, PAD, barY, WIDTH - PAD * 2, 24, 12);
  ctx.fillStyle = "rgba(255,255,255,0.08)";
  ctx.fill();

  const option0Width = Math.max(0, Math.min(1, question.options[0].pct / 100)) * (WIDTH - PAD * 2);
  ctx.save();
  roundedRect(ctx, PAD, barY, WIDTH - PAD * 2, 24, 12);
  ctx.clip();
  ctx.fillStyle = choice === 0 ? accent : "#2C3550";
  ctx.fillRect(PAD, barY, option0Width, 24);
  ctx.fillStyle = choice === 1 ? accent : "#2C3550";
  ctx.fillRect(PAD + option0Width, barY, WIDTH - PAD * 2 - option0Width, 24);
  ctx.restore();

  drawRoundImage(ctx, appIcon, PAD, 1186, 58);

  ctx.fillStyle = FAINT;
  ctx.font = "500 28px Inter, system-ui, sans-serif";
  ctx.fillText("Think clearly. Discuss respectfully.", PAD + 78, 1210);
  ctx.fillStyle = MUTED;
  ctx.font = "700 28px Inter, system-ui, sans-serif";
  ctx.fillText("societyofhomosapiens.org", PAD + 78, 1262);

  ctx.fillStyle = choice === 0 ? GOLD : TEAL;
  ctx.font = "700 30px Inter, system-ui, sans-serif";
  ctx.textAlign = "right";
  ctx.fillText(`I answered: ${chosen.label}`, WIDTH - PAD, 1262);
  ctx.textAlign = "left";

  return canvas.toDataURL("image/png");
}

export async function shareResultPng(options: ShareExportOptions): Promise<void> {
  const dataUrl = await renderSharePngDataUrl(options);
  const fileName = `sohs-day-${options.question.day}.png`;
  const title = "My SOhS answer";
  const text = "Think clearly. Discuss respectfully.";

  try {
    const file = await Filesystem.writeFile({
      path: fileName,
      data: dataUrlToBase64(dataUrl),
      directory: Directory.Cache,
    });
    await Share.share({
      title,
      text,
      url: file.uri,
      dialogTitle: "Share your SOhS answer",
    });
    return;
  } catch {
    if (Capacitor.getPlatform() !== "web") {
      throw new Error("Sharing was cancelled or is unavailable.");
    }

    const blob = dataUrlToBlob(dataUrl);
    const file = new File([blob], fileName, { type: "image/png" });
    const shareApi = navigator as Navigator & {
      canShare?: (data: { files: File[] }) => boolean;
      share?: (data: { title: string; text: string; files: File[] }) => Promise<void>;
    };

    if (shareApi.share && (!shareApi.canShare || shareApi.canShare({ files: [file] }))) {
      await shareApi.share({ title, text, files: [file] });
      return;
    }

    downloadDataUrl(dataUrl, fileName);
  }
}
