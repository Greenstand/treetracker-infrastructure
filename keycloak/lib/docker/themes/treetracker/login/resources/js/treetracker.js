// javascript to append a new div to body
var newDiv = document.createElement("div");
newDiv.innerHTML = `
<div class="tt-bg-credit">Find <a href="https://map.treetracker.org/planters/17356/trees/6282936" target="_blank" rel="noopener noreferrer">the tree on the background</a> on our web map.</div>
`;

// Append new div to body when the DOM is loaded
document.addEventListener("DOMContentLoaded", function (event) {
  document.body.appendChild(newDiv);
});
