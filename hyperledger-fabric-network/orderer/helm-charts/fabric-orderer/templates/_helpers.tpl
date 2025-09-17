{{- define "fabric-orderer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "fabric-orderer.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "fabric-orderer.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "fabric-orderer.labels" -}}
app.kubernetes.io/name: {{ include "fabric-orderer.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ include "fabric-orderer.fullname" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "fabric-orderer.ordererLabels" -}}
{{ include "fabric-orderer.labels" $ }}
app.kubernetes.io/component: orderer
{{- end }}
