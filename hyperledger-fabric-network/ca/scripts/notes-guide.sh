cd hyperledger-fabric-network/ca/scripts
chmod +x backup-ca.sh

./backup-ca.sh \
  --namespace hlf-ca \
  --client-pod fabric-ca-client-0 \
  --label 'app in (root-ca,greenstand-ca,cbo-ca,investor-ca,verifier-ca)'


cd hyperledger-fabric-network/ca/scripts
chmod +x restore-ca.sh

# Basic restore back into hlf-ca
./restore-ca.sh --archive /path/to/fabric-ca-backup-2025-08-08_201755.tgz

# Only re-apply K8s objects (Secrets/ConfigMaps)
./restore-ca.sh --archive ./fabric-ca-backup-*.tgz --no-data

# Restore into a different namespace (e.g., a test restore)
kubectl create ns test-ca
./restore-ca.sh --archive ./fabric-ca-backup-*.tgz --namespace test-ca

# Preview what would happen
./restore-ca.sh --archive ./fabric-ca-backup-*.tgz --dry-run --verbose

