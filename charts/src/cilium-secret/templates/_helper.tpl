{{- define "hexRand" -}}
    {{- $result := "" }}
    {{- range $i := until . }}
        {{- $rand_hex_char := mod (randNumeric 4 | atoi) 16 | printf "%x" }}
        {{- $result = print $result $rand_hex_char }}
    {{- end }}
    {{- $result = print "1 rfc4106(gcm(aes)) " $result " 128" }}
    {{- $result }}
{{- end }}
