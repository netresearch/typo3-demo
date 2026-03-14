/**
 * Fixed stickyheader for Bootstrap Package v16.
 * Replaces bootstrap.stickyheader.js which has a scroll flicker bug in Chromium
 * browsers (https://github.com/benjaminkott/bootstrap_package/issues/1468).
 *
 * Uses getBoundingClientRect().bottom as dynamic threshold instead of hardcoded
 * 120px, and checks class presence before toggling to prevent oscillation.
 * Credit: https://github.com/benjaminkott/bootstrap_package/issues/1468#issuecomment-2593684969
 */
window.addEventListener('DOMContentLoaded', function () {
    var stickyheader = document.querySelectorAll('.navbar-fixed-top');
    if (stickyheader.length >= 1) {
        function animateHeader() {
            if (window.scrollY >= stickyheader[0].getBoundingClientRect().bottom &&
                !stickyheader[0].classList.contains('navbar-transition')) {
                stickyheader[0].classList.add('navbar-transition');
            } else if (window.scrollY < stickyheader[0].getBoundingClientRect().bottom &&
                stickyheader[0].classList.contains('navbar-transition')) {
                stickyheader[0].classList.remove('navbar-transition');
            }
        }
        ['scroll', 'resize', 'DOMContentLoaded'].forEach(function (e) {
            window.addEventListener(e, animateHeader);
        });
        animateHeader();
    }
});
