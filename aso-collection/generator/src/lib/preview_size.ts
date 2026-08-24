type PreviewFormat = {
  width: number;
  height: number;
};

export function previewSize(format: PreviewFormat, height: number) {
  return {
    width: (format.width / format.height) * height,
    height,
  };
}
