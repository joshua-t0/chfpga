// Hide everything after the semicolon in navigation links
// Make navbar separators non-clickable
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
        
        // Detect separator links: check if href points to navbar_separator or if text is only dashes
        const href = link.getAttribute('href') || '';
        const linkText = link.textContent.trim();
        const isSeparator = href.includes('navbar_separator') || 
                           /^[-─━─\s]+$/.test(linkText);
        
        if (isSeparator) {
            // Remove href to prevent navigation
            link.removeAttribute('href');
            // Make it non-clickable via inline style
            link.style.pointerEvents = 'none';
            link.style.cursor = 'default';
        }
    });
});

