// Hide everything after the semicolon in navigation links
document.addEventListener('DOMContentLoaded', function() {
    // Find all navigation links
    const navLinks = document.querySelectorAll('.wy-menu-vertical a, .toctree-l1 a, .toctree-l2 a, .toctree-l3 a');
    
    navLinks.forEach(function(link) {
        const html = link.innerHTML;
        // Find the semicolon
        const semicolonIndex = html.indexOf(':');
        if (semicolonIndex !== -1) {
            // Keep everything up to but not including the semicolon
            link.innerHTML = html.substring(0, semicolonIndex).trim();
        }
    });
});

