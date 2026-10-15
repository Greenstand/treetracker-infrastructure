{{/* Maps keep per-node overrides addressable without replacing entire lists. */}}
{{- define "fabric-peers.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: hyperledger-fabric
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}
{{- define "fabric-peers.pod" -}}
{{- $p := deepCopy . -}}
{{- range $field := list "containers" "initContainers" -}}
  {{- if hasKey $p $field -}}
    {{- $list := list -}}
    {{- range $name, $source := get $p $field -}}
      {{- $c := deepCopy $source -}}
      {{- $_ := set $c "name" $name -}}
      {{- if hasKey $c "env" -}}
        {{- $env := list -}}
        {{- range $key, $value := $c.env -}}
          {{- $env = append $env (mergeOverwrite (dict "name" $key) (deepCopy $value)) -}}
        {{- end -}}
        {{- $_ := set $c "env" $env -}}
      {{- end -}}
      {{- $list = append $list $c -}}
    {{- end -}}
    {{- $_ := set $p $field $list -}}
  {{- end -}}
{{- end -}}
{{- $volumes := list -}}
{{- range $name, $volume := $p.volumes -}}
  {{- $volumes = append $volumes (mergeOverwrite (dict "name" $name) (deepCopy $volume)) -}}
{{- end -}}
{{- $_ := set $p "volumes" $volumes -}}
{{- toYaml $p -}}
{{- end }}
