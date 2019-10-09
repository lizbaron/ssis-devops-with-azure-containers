# Adapted from: https://github.com/Microsoft/mssql-docker/blob/master/windows/mssql-server-windows-developer/dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2019
LABEL maintainer "Sreeja P"

ARG TSQLT_DACPAC_URL="https://pkgs.dev.azure.com/pass2019/passdemo/_packaging/tfa/maven/v1/org/teachforamerica/dataplatform/db_tsqlt_ssis/1.0.0/db_tsqlt_ssis-1.0.0.dacpac"
ARG ADVENTURE_WORKS_BAK_URL="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2017.bak"


# Download Links:
ENV exe "https://go.microsoft.com/fwlink/?linkid=840945"
ENV box "https://go.microsoft.com/fwlink/?linkid=840944"

ENV sa_password="W3lc0mE002" \
    attach_dbs="[]" \
    ACCEPT_EULA="Y" \
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /

COPY deployDacpacs.ps1 /
COPY changeSqlLogin.ps1 /
COPY setupSSIS.ps1 /

#need to change the command to include "IS"
RUN Invoke-WebRequest -Uri $env:box -OutFile SQL.box ; \
        Invoke-WebRequest -Uri $env:exe -OutFile SQL.exe ; \
        Start-Process -Wait -FilePath .\SQL.exe -ArgumentList /qs, /x:setup ; \
        .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine,IS /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS ; \
	Remove-Item -Recurse -Force SQL.exe, SQL.box, setup

# SqlPackage.exe (for applying schema from Visual Studio)
ADD https://download.microsoft.com/download/9/2/2/9228AAC2-90D1-4F48-B423-AF345296C7DD/EN/x64/DacFramework.msi /DacFramework.msi
RUN Start-Process -FilePath 'msiexec.exe'                         \
        -ArgumentList '/quiet','/qn','/norestart',                \
                      '/log','\DacFramework.log',                 \
                      '/i','\DacFramework.msi'                    \
        -Wait

ADD create_ssis_catalog.ps1 SSIS_SCRIPTS/
ADD enable_clr_integration.sql SSIS_SCRIPTS/
ADD deploy_ssis_package.ps1 SSIS_SCRIPTS/

RUN .\changeSqlLogin -sa_password $env:sa_password
RUN .\setupSSIS

# Deploy dacpacs before stopping sql server
RUN Invoke-WebRequest -Uri $env:TSQLT_DACPAC_URL -OutFile TSQLT.dacpac ; \
    Invoke-WebRequest -Uri $env:ADVENTURE_WORKS_BAK_URL -OutFile  ADVENTURE_WORKS.bak ;\	
	.\deployDacpacs -sa_password $env:sa_password

RUN stop-service MSSQLSERVER ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ; \
        set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql14.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2 ;

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

#Install Java
# Set up chocolatey to install java
ENV chocolateyUseWindowsCompression false

#Install chocolatey via powershell
RUN powershell -Command Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
RUN choco feature disable --name showDownloadProgress
RUN choco install openjdk -y
 
COPY start.ps1 /

RUN net user /add LOCAL_SQLSRVR

RUN powershell -Command Add-LocalGroupMember -Group "Administrators" -Member "LOCAL_SQLSRVR"

USER LOCAL_SQLSRVR

CMD .\start -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -sqlsrvrlogin "LOCAL_SQLSRVR" -Verbose
