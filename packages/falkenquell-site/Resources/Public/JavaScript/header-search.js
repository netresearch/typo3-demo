(() => {
    const toggle = document.querySelector('[data-header-search-toggle]');
    const panel = document.getElementById('header-search');
    if (!toggle || !panel) {
        return;
    }
    const input = panel.querySelector('input');

    const setOpen = (open) => {
        panel.hidden = !open;
        toggle.setAttribute('aria-expanded', String(open));
        if (open) {
            input.focus();
        }
    };

    toggle.addEventListener('click', () => setOpen(panel.hidden));
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && !panel.hidden) {
            setOpen(false);
            toggle.focus();
        }
    });
})();
