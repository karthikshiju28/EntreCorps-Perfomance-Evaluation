import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Report PDFs are uploaded through a Server Action (default limit is 1 MB).
  experimental: { serverActions: { bodySizeLimit: "10mb" } },
};

export default nextConfig;
