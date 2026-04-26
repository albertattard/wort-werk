apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wortwerk
  namespace: ${APP_NAMESPACE}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - ${APP_HOST}
      secretName: wortwerk-tls
  rules:
    - host: ${APP_HOST}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: wortwerk-active
                port:
                  number: 80
