// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sitemap from '@astrojs/sitemap';
import { generatedSidebar } from './sidebar.generated.mjs';

const site = 'https://danielvm-git.github.io';
const base = '/bigpowers';

// https://astro.build/config
export default defineConfig({
	site,
	base,
	integrations: [
		starlight({
			title: 'bigpowers',
			description:
				'Agent skills synthesizing 17 years of software engineering discipline into a prescriptive methodology for solo developers.',
			editLink: {
				baseUrl: 'https://github.com/danielvm-git/bigpowers/edit/main/',
			},
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/danielvm-git/bigpowers',
				},
			],
			head: [
				{
					tag: 'meta',
					attrs: {
						name: 'generator',
						content: 'bigpowers docs prebuild',
					},
				},
				{
					tag: 'meta',
					attrs: {
						property: 'og:site_name',
						content: 'bigpowers',
					},
				},
				{
					tag: 'meta',
					attrs: {
						property: 'og:type',
						content: 'website',
					},
				},
			],
			sidebar: generatedSidebar,
		}),
		sitemap(),
	],
});
