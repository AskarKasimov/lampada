export class ExportTimeoutError extends Error {
  constructor(label) {
    super(`Экспорт «${label}» не завершился за отведённое время. Попробуйте ещё раз.`);
    this.name = "ExportTimeoutError";
  }
}

export function withTimeout(promise, timeoutMs, label) {
  let timeoutId;
  const timeout = new Promise((_, reject) => {
    timeoutId = setTimeout(() => reject(new ExportTimeoutError(label)), timeoutMs);
  });

  return Promise.race([promise, timeout]).finally(() => clearTimeout(timeoutId));
}
