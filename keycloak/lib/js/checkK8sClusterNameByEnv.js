// usage: node checkK8sClusterNameByEnv.js <env> <clusterName>
// output: true|false
const env = process.argv[2];
const clusterName = process.argv[3];

// name array, can add more if needed, in case setting up the config varies.
const clusterNames = {
  dev: ['do-sfo2-dev-k8s-treetracker'],
  test: ['do-sfo2-test-k8s-treetracker'],
  prod: ['do-sfo2-prod-k8s-treetracker'],
};

if (clusterNames[env].includes(clusterName)) {
  console.log('true');
}else {
  console.log('false');
}
