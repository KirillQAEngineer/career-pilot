const config = {
  title: 'JobCompass Docs',
  tagline: 'Документация платформы JobCompass',
  url: 'https://kirillqaengineer.github.io',
  baseUrl: process.env.DOCS_BASE_URL || '/docs/',
  organizationName: 'KirillQAEngineer',
  projectName: 'JobCompass',
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  i18n: {
    defaultLocale: 'ru',
    locales: ['ru'],
  },
  plugins: [
    [
      '@docusaurus/plugin-content-docs',
      {
        sidebarPath: require.resolve('./sidebars.js'),
        routeBasePath: '/',
      },
    ],
  ],
  themes: [
    [
      '@docusaurus/theme-classic',
      {
        customCss: require.resolve('./src/css/custom.css'),
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'JobCompass Docs',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'mainSidebar',
          position: 'left',
          label: 'Документация',
        },
      ],
    },
    footer: {
      style: 'dark',
      copyright: `JobCompass ${new Date().getFullYear()}`,
    },
    prism: {
      additionalLanguages: ['bash', 'dart', 'python'],
    },
  },
};

module.exports = config;
