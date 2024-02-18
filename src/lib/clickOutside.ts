/** Dispatch event on click outside of node */
export function clickOutside(node: HTMLElement) {
	const handleClick = (event: MouseEvent) => {
		if (node && !node.contains(event.target as HTMLElement) && !event.defaultPrevented) {
			node.dispatchEvent(
				new CustomEvent<ClickOutsideEvent>('click_outside', {
					detail: { node, clickedElement: event.target as HTMLElement }
				})
			);
		}
	};

	document.addEventListener('click', handleClick, true);

	return {
		destroy() {
			document.removeEventListener('click', handleClick, true);
		}
	};
}
