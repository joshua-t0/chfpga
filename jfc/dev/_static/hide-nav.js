// Hide everything after the semicolon in navigation links (sidebar only)
// Make navbar separators non-clickable
// Hide separator list items when not in the navbar
document.addEventListener('DOMContentLoaded', function() {
    // Find all navigation links - only in the sidebar, not in main content
    // Scope toctree selectors to the sidebar menu container
    const navLinks = document.querySelectorAll('.wy-menu-vertical a, .wy-menu-vertical .toctree-l1 a, .wy-menu-vertical .toctree-l2 a, .wy-menu-vertical .toctree-l3 a');
    
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
    
    // Hide separator list items that are NOT in the navbar (i.e., in main content)
    // Find all separator links in the main content area
    const mainContent = document.querySelector('.rst-content');
    if (mainContent) {
        const mainContentSeparators = mainContent.querySelectorAll('a[href*="navbar_separator"], .toctree-wrapper a');
        mainContentSeparators.forEach(function(link) {
            const href = link.getAttribute('href') || '';
            const linkText = link.textContent.trim();
            const isSeparator = href.includes('navbar_separator') || 
                               /^[-─━─\s]+$/.test(linkText);
            
            if (isSeparator) {
                // Find the parent list item and hide it
                const listItem = link.closest('li');
                if (listItem) {
                    listItem.style.display = 'none';
                }
            }
        });
    }
});

