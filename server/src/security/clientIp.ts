// Client IP resolution. IPs are used for in-memory rate-limit buckets only
// and are never stored or logged. See PLAN.md 6.9.
// CF-Connecting-IP is trusted only when TRUST_CLOUDFLARE is true, which
// requires the origin firewall to accept Cloudflare ranges only.

/** Resolve the client IP from the socket or the Cloudflare header. */
export function clientIp(
  socketAddr: string | null,
  cfConnectingIp: string | null,
  trustCloudflare: boolean,
): string {
  if (trustCloudflare && cfConnectingIp && cfConnectingIp !== "") {
    return cfConnectingIp.trim();
  }
  return socketAddr ?? "unknown";
}
