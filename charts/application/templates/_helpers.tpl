{{/*
Expand the name of the chart.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.global.releaseVersion }}
app.kubernetes.io/release-version: {{ .Values.global.releaseVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Override the name of the service to use
*/}}
{{- define "app.service-name" -}}
{{- if .Values.service.nameOverride }}
{{- default "default" .Values.service.nameOverride }}
{{- else }}
{{- default (include "app.fullname" .) .Values.service.nameOverride }}
{{- end }}
{{- end }}

{{/*
Custom environment variables
*/}}
{{- define "app.env" -}}
{{- $envVars := mergeOverwrite (dict) (mergeOverwrite (dict) .Values.deployment.env) (mergeOverwrite (dict) .Values.global.env) -}}
{{- range $envVarName, $envVarValue := $envVars }}
{{- if typeIs "string" $envVarValue }}
- name: {{ $envVarName | quote }}
  value: {{ tpl $envVarValue $ | quote }}
{{- else if typeIs "map[string]interface {}" $envVarValue }}
- name: {{ $envVarName | quote }}
{{- tpl ( toYaml $envVarValue ) $ | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Extra labels for POD
*/}}
{{- define "app.extraLabels" -}}
{{- if .Values.global.extraLabels }}
{{ tpl (toYaml .Values.global.extraLabels | trim) . }}
{{- end -}}
{{- end -}}

{{/*
Define namespace variable
*/}}
{{- define "app.namespace" -}}
{{- .Release.Namespace }}
{{- end }}
