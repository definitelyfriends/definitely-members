/** @type {import('next').NextConfig} */
module.exports = {
  reactStrictMode: true,
  async redirects() {
    return [
      {
        source: "/contract",
        destination: "https://etherscan.io/",
        permanent: false,
      },
    ];
  },
};
