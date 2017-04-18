#!/bin/sh
#**************************************************************************************************
#   Functions for the "Baikal Server" scripts, to install as package on Synology system
#   Copyright (C) 2014  Basalt
#--------------------------------------------------------------------------------------------------
#   Baïkal Server, a lightweight CalDAV and CardDAV server.
#   Copyright (C) 2012  Jérôme Schneider
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#--------------------------------------------------------------------------------------------------
# 12jan14 EB    First version for Baikal 0.2.6 "Flat package".
#**************************************************************************************************

#-------------------------------------------
# App specific
# Please keep synced with start-stop-status
#-------------------------------------------
AppExt=".app"
AppDir=/var/services/web/${SYNOPKG_PKGNAME}${AppExt}
DataName="Specific"
DataFullPath=${AppDir}/${DataName}
MigrationDir=${SYNOPKG_PKGDEST}/../${SYNOPKG_PKGNAME}_data_migration

# Please make sure LogFile is the same in start-stop-status and functions.sh
LogFile=/var/log/${SYNOPKG_PKGNAME}.log

#--------------------------------------------------------------------------------------------------
#   At command completion, Package Center will show the logged information in a popup
#   Prefix can be used for different types of information, e.g.
#       "DEBUG: this is debug info"
#       "ERROR: something went wrong"
#
#   Also logging to permanent file, accessible via Package Center "Log" link
#
#   Code can be simply adjusted to filter certain types.
#--------------------------------------------------------------------------------------------------
log()   # argument $1=text to log
{
    local prefix=`echo $1|sed "s/:.*$//g"`
    if [ "${prefix}" != "DEBUG" ]; then
        if [ "${prefix}" != "INFO" ]; then
            echo "$1" >> ${SYNOPKG_TEMP_LOGFILE}
        fi
        echo "$(date "+%d-%b-%y %H:%M:%S") ${SYNOPKG_PKG_STATUS},$1" >> ${LogFile}
    fi
}

#--------------------------------------------------------------------------------------------------
#   Local functions for safe recursive functions on directories
#--------------------------------------------------------------------------------------------------
remove_AppDir()
{
    log "DEBUG: remove AppDir=\"${AppDir}\""
    
    if [ -d "${AppDir}" ]; then
        if  [ -z "${AppDir}" ] ||
            [ -z "${SYNOPKG_PKGNAME}" ] ||
            [ "`basename "${AppDir}"`" != "${SYNOPKG_PKGNAME}${AppExt}" ]; then
            log "ERROR: something is terribly wrong with AppDir=\"${AppDir}\"!!"
            exit 1
        fi

        rm -rf "${AppDir}"
        if [ $? -ne 0 ]; then
            log "WARNING: removing AppDir=\"${AppDir}\" has failed, you may need to cleanup manually"
        fi
    #else: not there anyway, ignore
    fi
}

remove_orgData()
{
    log "DEBUG: remove original data=\"${DataFullPath}.org\""
    
    if [ -d "${DataFullPath}.org" ]; then
        if  [ -z "${DataFullPath}"] ||
            [ "`basename "${DataFullPath}"`" != "${DataName}" ]; then
            log "ERROR: something is terribly wrong with original data dir=\"${DataFullPath}.org\""
            exit 1
        fi
        rm -rf "${DataFullPath}.org"
        if [ $? -ne 0 ]; then
            log "WARNING: removing original data dir=\"${DataFullPath}.org\" has failed, you may need to cleanup manually"
        fi
    #else: not there anyway, ignore
    fi
}

chmod_Data()
{
    log "DEBUG: chmod and chown data=\"${DataFullPath}\""
    
    if [ -d "${DataFullPath}" ]; then
        if  [ -z "${DataFullPath}" ] ||
            [ "`basename "${DataFullPath}"`" != "${DataName}" ]; then
            log "ERROR: something is terribly wrong with data dir=\"${DataFullPath}.org\""
            exit 1
        fi
        chmod -R 770 ${DataFullPath}
        if [ $? -ne 0 ]; then
            log "WARNING: chmod on data dir=\"${DataFullPath}\" has failed, you may need to change manually"
        fi
        chown -R nobody:nobody ${DataFullPath}
        if [ $? -ne 0 ]; then
            log "WARNING: chown on data dir=\"${DataFullPath}\" has failed, you may need to change manually"
        fi
    fi
}

#==================================================================================================
#   Install package
#==================================================================================================
preinst()
{
    log "INFO: performing installation of \"${SYNOPKG_PKGNAME}\" version \"${SYNOPKG_PKGVER}\""
    remove_AppDir
    exit 0
}

postinst()
{
    log "DEBUG: post processing installation"
    log "DEBUG: SYNOPKG_PKGDEST=${SYNOPKG_PKGDEST}"
    log "DEBUG: DataName=${DataName}"
    log "DEBUG: DataFullPath=${DataFullPath}"
    
    # Install package into Web space
    # (for security reasons, linking to ${SYNOPKG_PKGDEST} does not work)
    mv ${SYNOPKG_PKGDEST}/flat ${AppDir}
    if [ $? -ne 0 ]; then
        log "ERROR: failed to install into AppDir=\"${AppDir}\""
        exit 1
    fi

    if [ ${SYNOPKG_PKG_STATUS} != "UPGRADE" ]; then
        # Enable the Install Wizard for 1 hour after installing
        touch ${DataFullPath}/ENABLE_INSTALL
        if [ $? -ne 0 ]; then
            log "WARNING: cannot enable the Install Wizard, path=\"${DataFullPath}/ENABLE_INSTALL\""
        fi
    #else: After 1 hour, Install Wizard will not run, even if we do touch ENABLE_INSTALL
    # In that case you will have to uninstall/install
    fi
    
    log "INFO: installation of \"${SYNOPKG_PKGVER}\" finished"
    exit 0
}

#==================================================================================================
#   Uninstall package
#==================================================================================================
preuninst()
{
    log "DEBUG: uninstall started"
    exit 0
}

postuninst()
{
    remove_AppDir
    log "DEBUG: post processing uninstall"
    if [ ${SYNOPKG_PKG_STATUS} != "UPGRADE" ]; then
        if [ -L /var/packages/${SYNOPKG_PKGNAME}/etc ]; then
            # Try to remove where this "etc" link points at
            # (Package Center keeps it for some reason)
            local etcdir=`readlink /var/packages/${SYNOPKG_PKGNAME}/etc`
            if [ $? -eq 0 ] && [ ! -z "${etcdir}" ] && [ -d "${etcdir}" ]; then
                log "DEBUG: try to remove \"${etcdir}\""
                rmdir "${etcdir}"
                # ignore errors, data may be present for some reason, keep it
            fi
        fi
        # Finally, remove our log file
        rm ${LogFile}
    fi
    exit 0
}

#==================================================================================================
#   Upgrade package
#==================================================================================================
preupgrade()
{
    log "INFO: performing upgrade of \"${SYNOPKG_PKGNAME}\" from \"${SYNOPKG_OLD_PKGVER}\" to \"${SYNOPKG_PKGVER}\""
    log "DEBUG: SYNOPKG_PKGDEST=${SYNOPKG_PKGDEST}"
    log "DEBUG: DataName=${DataName}"
    log "DEBUG: DataFullPath=${DataFullPath}"
    log "DEBUG: MigrationDir=${MigrationDir}"
    
    if [ ! -d ${DataFullPath} ]; then
        log "ERROR: cannot upgrade, because required data directory \"${DataFullPath}\" does not exist. Manually restore a backup an try again (or use uninstall/install instead)"
        exit 1
    fi

    if [ -d ${MigrationDir} ]; then
        log "ERROR: old data backup directory \"${MigrationDir}\" is still present. Please cleanup manually"
        exit 1
    fi

    # Save migration data
    mkdir ${MigrationDir}
    if [ $? -ne 0 ]; then
        log "ERROR: cannot create backup directory \"${MigrationDir}\""
        exit 1
    fi

    cp -pr ${DataFullPath} ${MigrationDir}
    if [ $? -ne 0 ]; then
        log "ERROR: failed to backup data \"${DataFullPath}\" into directory \"${MigrationDir}\""
        exit 1
    fi
    log "INFO: made data backup into directory \"${MigrationDir}\""

    log "DEBUG: preparation ok, perform upgrade"
    exit 0
}

postupgrade()
{
    log "DEBUG: post processing upgrade"
    
    #restore data folder
    if [ -d ${MigrationDir}/${DataName} ]; then
        # Save default data first, so at least we can rollback to that
        remove_orgData
        mv ${DataFullPath} ${DataFullPath}.org
        if [ $? -ne 0 ]; then
            log "ERROR: failed to replace \"${DataFullPath}\", you may need to restore a data backup manually"
            exit 1
        fi
        
        # Restore migration data
        mv ${MigrationDir}/${DataName} ${AppDir}
        if [ $? -ne 0 ]; then
            log "ERROR: failed to restore data from \"${MigrationDir}/${DataName}\" into \"${AppDir}\". Rolling back to default installation data, you may need to restore a backup manually"
            mv ${DataFullPath}.org ${DataFullPath}
            exit 1
        fi
        chmod_Data
        
        # Cleanup migration data
        rmdir ${MigrationDir}
        if [ $? -ne 0 ]; then
            log "WARNING: failed to cleanup backup data in \"${MigrationDir}\", this may cause problems with future upgrade"
        fi

        # Cleanup default data
        remove_orgData
        log "INFO: data restored"
    else
        log "ERROR: no backup data in \"${MigrationDir}/${DataName}\". Keeping default installation data instead, you may need to restore a backup manually"
        exit 1
    fi

    log "INFO: upgrade to \"${SYNOPKG_PKGVER}\" finished"
    exit 0
}
