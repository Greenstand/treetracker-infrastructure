// javascript to append a new div to body
var newDiv = document.createElement("div");
newDiv.innerHTML = `
<div style="
    position: fixed;
    bottom: 0px;
    margin: 10px 20px;
    background-color: #09090980;
    color: white;
    font-size: 16px;
    padding: 5px;
">Find <a href="https://map.treetracker.org/planters/17356/trees/6282936" target="_blank" >the tree on the background</a> on our web map.</div>
`;

// Append new div to body when the DOM is loaded
document.addEventListener("DOMContentLoaded", function(event) {
  document.body.appendChild(newDiv);
});
