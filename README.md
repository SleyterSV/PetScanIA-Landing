# PetScanIA

Aplicacion Flutter para cuidado de mascotas, comunidad local, adopciones,
campanas gratuitas, historial medico familiar y acceso rapido por WhatsApp.

## Actualizacion principal

- Login por numero telefonico con flujo de codigo por WhatsApp.
- Seccion "Adopta y ayuda" para adopciones, mascotas perdidas y encontradas.
- Campanas gratuitas visibles desde el inicio.
- Historial medico familiar con permisos compartidos.
- Roles de usuario: familia/cliente, veterinario, refugio/rescatista y admin.
- Esquema Supabase base en `supabase/petscania_family_roles_schema.sql`.

## Ejecutar

```powershell
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 53731
```

Abrir:

```text
http://127.0.0.1:53731
```

## Supabase

Antes de usar familia, roles, campanas e historial medico en produccion,
ejecutar el SQL de `supabase/petscania_family_roles_schema.sql` en el panel de
Supabase.
