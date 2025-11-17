# Correção de Bug - HLL Geofences

## Bug Corrigido

Foi identificado e corrigido um bug crítico na biblioteca `go-hll-rcon` que causava crashes constantes (SIGSEGV - segmentation violation).

### Problema
O sistema estava crashando a cada ~20 segundos com erro:
```
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x38 pc=0x55f256]
```

### Causa
No arquivo `vendor/github.com/floriansw/go-hll-rcon/rconv2/protocol.go`, função `reconnect()`:
- Quando `makeConnectionV2()` falhava, retornava `err != nil` e `con == nil`
- O código continuava e atribuía `r.con = con` (nil)
- Na linha seguinte, `r.SetContext()` tentava usar `r.con.SetDeadline()` causando crash

### Solução
Adicionada verificação de erro antes de usar a conexão:
```go
con, err := makeConnectionV2(r.host, r.port)
if err != nil {
    return fmt.Errorf("connection failed: %w, original error: %v", err, orig)
}
r.con = con
```

### Como Aplicar o Patch

1. Após fazer `go mod vendor`, aplique o patch:
```bash
patch -p1 < patches/rcon-fix.patch
```

2. Ou edite manualmente o arquivo `vendor/github.com/floriansw/go-hll-rcon/rconv2/protocol.go`

3. Rebuild os containers:
```bash
docker compose build --no-cache
docker compose up -d
```

### Alterações no Dockerfile

Modificado para usar vendor mode e garantir que o patch seja aplicado:
```dockerfile
FROM golang:1.24-alpine
WORKDIR /app
COPY . .
RUN go build -mod=vendor -o hll-geofences ./cmd/cmd.go
CMD ["./hll-geofences"]
```

### Resultado
✅ Sistema rodando sem crashes
✅ Erros de conexão agora são tratados adequadamente
✅ Logs limpos mostrando apenas timeouts de conexão (não crashes)
