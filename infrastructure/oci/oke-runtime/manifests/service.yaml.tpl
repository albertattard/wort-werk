apiVersion: v1
kind: Service
metadata:
  name: wortwerk-active
  namespace: ${APP_NAMESPACE}
  labels:
    app.kubernetes.io/name: wortwerk
spec:
  type: ${SERVICE_TYPE}
  selector:
    app.kubernetes.io/name: wortwerk
    app.kubernetes.io/slot: ${ACTIVE_SLOT}
  ports:
    - name: http
      port: 80
      targetPort: http
