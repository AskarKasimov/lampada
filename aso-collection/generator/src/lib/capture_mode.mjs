/**
 * @param {string} search
 * @param {string[]} slideIds
 * @param {string[]} formatIds
 * @returns {{slideId: string, formatId: string} | null}
 */
export function captureMode(search, slideIds, formatIds) {
  const params = new URLSearchParams(search);
  const slideId = params.get("capture");
  const formatId = params.get("format");

  if (!slideIds.includes(slideId) || !formatIds.includes(formatId)) {
    return null;
  }

  return { slideId, formatId };
}
