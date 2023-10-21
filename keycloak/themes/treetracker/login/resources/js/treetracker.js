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
">On the background, it is one tree on the system, which is a mangrove capable of trapping a ton of carbon - if it can survive a city where some 800 thousand people rely on wood to cook; The chances that it will survive are drastically increased by payments made to the grower who guards it. Our work is creating green employment for people, check <a href="https://map.treetracker.org/?treeid=5457697">this tree</a> on our map.</div>
`;

// Append new div to body when the DOM is loaded
document.addEventListener("DOMContentLoaded", function(event) {
  document.body.appendChild(newDiv);
});
