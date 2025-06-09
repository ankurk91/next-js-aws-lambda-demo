import type {NextConfig} from "next";
import {PHASE_DEVELOPMENT_SERVER} from "next/constants";

const config = (phase: string) => {
    const isDev = phase === PHASE_DEVELOPMENT_SERVER

    /**
     * @type {import('next').NextConfig}
     */
    const nextConfig: NextConfig = {
        assetPrefix: isDev ? undefined : process.env.NEXT_ASSET_PREFIX_URL,
        poweredByHeader: false,
        compress: false,
        output: "standalone",
        expireTime: 86400,
        images: {
            minimumCacheTTL: 86400,
            unoptimized: true,
            remotePatterns: [
                //
            ],
        },
        compiler: {
            removeConsole: isDev ? false : {
                exclude: ["error", "warn"]
            },
        },
        /* other config options here */

    };

    return nextConfig;
}

export default config;
