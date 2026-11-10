# Library Mk5 — local-network deployment testing (Windows 11 / Windows 10)

## Release status

**Deployment-test candidate, NOT verified live-event release.** This package is Rails source code with Windows launchers, not a bundled Ruby/PostgreSQL executable. It needs Ruby, Bundler, PostgreSQL and the gems in Gemfile.lock installed on the host. Windows 10 compatibility is not verified; Windows 10 is out of Microsoft general support. Automated checks and browser/database restore tests must pass on the target machine.

## Intended arrangement

One Windows 11 host (Windows 10 alternative) runs Ruby/Rails and PostgreSQL locally. Other computers open `http://HOST-IP:3000` on the same trusted Wi-Fi/Ethernet LAN. No extra application login was added at the user's request. **Do not port-forward port 3000 or expose it to the internet.** Configure Windows Firewall inbound TCP 3000 for **Private** network profile and trusted local subnet only, never Public. Rails binds `0.0.0.0` to accept LAN clients; PostgreSQL remains on localhost.

## Before doing anything

1. Keep your original project and database unchanged. Make a PostgreSQL custom-format backup of the original database with pgAdmin, and verify that you can restore it into a new database.
2. Copy this folder to a NEW folder on the host, e.g. `C:\LibraryMk5Test`. Do not overwrite your working application.
3. Install compatible Ruby 4.0.9 + Bundler, PostgreSQL (tested source configuration was 18.6), and Git if required by Bundler. The app uses Rails 8.1.4.1. Ensure `ruby` and `bundle` work in a newly opened PowerShell window. Use matching architecture and PostgreSQL client libraries.
4. In PowerShell, set the intended **restored** database name: `$env:LIBRARY_PROD_DB = 'library_mk5_restore_test'` (replace with your real restored copy's name). Never point the test run at the only live database. You can set it per session, or the launcher will prompt for it.
5. The PostgreSQL password is prompted at launch and is **not stored in the project**. Change any password that has been shared in chat before future use.

## One-time install and verification

1. Double-click `01_Install_Dependencies.bat` (requires network access for missing gems). Fix any gem/native extension errors before proceeding.
2. Double-click `02_Verify_Test_Environment.bat`. It will prompt for the PostgreSQL password, ask for explicit confirmation before loading the disposable `library_mk4_test` test database, run Rails tests and precompile production assets. **Never set LIBRARY_TEST_DB to a real database.**
3. Restore the existing library backup to a NEW database using pgAdmin Restore. Do not restore over the live database. Note its database name.
4. Double-click `03_Start_Library.bat`; enter the restored database name, confirm it exactly, and keep the window open. The launcher generates a private signing secret on first use, connects to the selected database and starts Rails on all local network interfaces at port 3000. It does **not** run migrations or reset a database.
5. Open `http://localhost:3000` on the host, then `http://HOST-IP:3000` on another computer. Find HOST-IP with `ipconfig` on the host. Both devices must be on the same LAN; use Private network firewall profile. Do not expose the service to a public network.
6. Test event setup, game lookup, barcode registration, checkout/return, attendee handling, reports, tournaments and storage using **test records in the restored database**. Compare game/event/attendee counts to the original backup. Stop the server with Ctrl+C.

## Backups and go-live

`04_Backup_Database.bat` uses `pg_dump -Fc` to save a timestamped backup under `deployment/backups/`. It does not restore or delete data. Move copies off the host. A backup is not fully validated until a successful test restore. Before live use, back up the actual live database, confirm all deployment tests, and intentionally select the correct production database. Avoid running `db:drop`, `db:reset`, `db:schema:load`, `db:setup`, `db:prepare`, or unreviewed migrations against real records. The project defaults to `library_mk4_prod` only when explicitly configured by Rails; the start launcher requires a database name to be selected and confirmed.

## Startup on Windows 10 / 11

The four `.bat` launchers work through Windows PowerShell 5.1 on either OS. Windows 11 is the primary target. Windows 10 may require a compatible RubyInstaller, MSYS2 and PostgreSQL version; confirm supported versions before installation. The launcher keeps its console open while Rails runs. There is **no unattended Windows-service autostart** because the database password is requested each time and this deployment-test build should not silently start against a live database. A Windows service can be configured after testing with a securely managed credential mechanism.

## Troubleshooting

- `ruby` / `bundle` not recognized: install Ruby and reopen the terminal.
- `pg_dump` not found: install PostgreSQL command-line tools or check `C:\Program Files\PostgreSQL\VERSIONin`.
- PostgreSQL connection refused: start the PostgreSQL Windows service and confirm port 5432.
- Password authentication failed: enter the PostgreSQL user's actual password; do not edit the source to hard-code it.
- Host works but clients cannot connect: verify host IPv4 (`ipconfig`), same LAN, firewall Private profile and inbound TCP 3000; avoid guest Wi-Fi client isolation.
- CSS missing: run `02_Verify_Test_Environment.bat` to precompile assets.
- Database schema error: stop and inspect migration status against a **restored copy**, never reset the live database.
- Sass `@import` deprecation messages are warnings, not test failures.

## Known limits

Source syntax checks were previously performed on 83 Ruby files, but the Rails runtime and actual Windows host environment have **not** been executed in this container. The current test suite is small and cannot certify all business workflows. This is an installation/testing candidate only. No passwords or actual library data are included. The app has no additional authentication, so only use it on a trusted LAN.
