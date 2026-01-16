export function log(scope: string, message: string, data?: unknown) {
  console.log(
    `%c[${scope}]`,
    "color:#22c55e;font-weight:bold",
    message,
    data ?? ""
  );
}

export function formatAccount(addr: string) {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}
