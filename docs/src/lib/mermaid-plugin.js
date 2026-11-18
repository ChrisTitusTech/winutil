// Turns ```mermaid fences into <pre class="mermaid"> before Expressive Code sees them; MarkdownContent.astro draws them.
/** @type {import('@astrojs/markdown-satteri').SatteriProcessorOptions['hastPlugins'][number]} */
export const mermaidPlugin = {
	name: 'mermaid',
	element: {
		filter: ['pre'],
		visit(node, ctx) {
			const [code] = node.children;
			if (code?.type !== 'element' || code.data?.lang !== 'mermaid') return;
			return {
				type: 'element',
				tagName: 'pre',
				properties: { className: ['mermaid'] },
				children: [{ type: 'text', value: ctx.textContent(code) }],
			};
		},
	},
};
