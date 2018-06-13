--[[
        ExtendedManager.lua
--]]


local ExtendedManager, dbg = Manager:newClass{ className='ExtendedManager' }



--[[
        Constructor for extending class.
--]]
function ExtendedManager:newClass( t )
    return Manager.newClass( self, t )
end



--[[
        Constructor for new instance object.
--]]
function ExtendedManager:new( t )
    return Manager.new( self, t )
end



--- Initialize global preferences.
--
function ExtendedManager:_initGlobalPrefs()
    -- Instructions: delete the following line (or set property to nil) if this isn't an export plugin.
    -- fprops:setPropertyForPlugin( _PLUGIN, 'exportMgmtVer', "2" ) -- a little add-on here to support export management. '1' is legacy (rc-common-modules) mgmt.
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initGlobalPref( 'exifToolApp', "" )
    -- app:initGlobalPref( 'mogrifyApp', "" )
    app:setGlobalPref( 'catalog', nil )
    app:initGlobalPref( 'sqliteApp', "" )
    Manager._initGlobalPrefs( self )
end



--- Initialize local preferences for preset.
--
function ExtendedManager:_initPrefs( presetName )
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initPref( 'exifToolApp', "" )
    -- app:initPref( 'mogrifyApp', "" )
    -- app:initPref( 'sqliteApp', "", presetName )
    -- *** Instructions: delete this line if no async init or continued background processing:
    app:setPref( 'background', nil, presetName ) -- true to support on-going background processing, after async init (auto-update most-sel photo).
    -- *** Instructions: delete these 3 if not using them:
    app:setPref( 'processTargetPhotosInBackground', nil, presetName )
    app:setPref( 'processFilmstripPhotosInBackground', nil, presetName )
    app:setPref( 'processAllPhotosInBackground', nil, presetName )
    Manager._initPrefs( self, presetName )
end



--- Start of plugin manager dialog.
-- 
function ExtendedManager:startDialogMethod( props )
    -- *** Instructions: uncomment if you use these apps and their exe is bound to ordinary property table (not prefs).
    self.sqlite = ExternalApp:new{ prefName = 'sqliteApp', winExeName="sqlite3.exe", macAppName="sqlite3" }
    view:setObserver( prefs, app:getGlobalPrefKey( 'sqliteApp' ), Manager, Manager.prefChangeHandler )
    --view:setObserver( prefs, app:getGlobalPrefKey( 'catalog' ), Manager, Manager.prefChangeHandler )
    Manager.startDialogMethod( self, props ) -- adds observer to all props.
end



--- Preference change handler.
--
--  @usage      Handles preference changes.
--              <br>Preferences not handled are forwarded to base class handler.
--  @usage      Handles changes that occur for any reason, one of which is user entered value when property bound to preference,
--              <br>another is preference set programmatically - recursion guarding is essential.
--
function ExtendedManager:prefChangeHandlerMethod( _props, _prefs, key, value )
    local name = app:getGlobalPrefName( key )
    if name == 'sqliteApp' then
        --[[
        Debug.pause( "sqlite", name )
        if not str:is( value ) then
            app:show{ info="Built-in default sqlite app/exe will be used." }
        else
            app:show{ info="Custom sqlite app/exe will be used: ^1", value }
        end
        app:setGlobalPref( name, value )
        --]]
        self.sqlite:processExeChange( value )
    elseif name == 'catalog' then
        Debug.pause( "catalog", name )
        local me = catalog:getPath()
        if value == me then
            app:show{ warning="You have selected the active catalog - you will have to restart Lightroom with a different catalog to do the deed." }
        else
            app:setGlobalPref( name, value )
        end
    else
        Manager.prefChangeHandlerMethod( self, _props, _prefs, key, value ) -- set-global-pref.
    end
end



--- Property change handler.
--
--  @usage      Properties handled by this method, are either temporary, or
--              should be tied to named setting preferences.
--
function ExtendedManager:propChangeHandlerMethod( props, name, value, call )
    if app.prefMgr and (app:getPref( name ) == value) then -- eliminate redundent calls.
        -- Note: in managed cased, raw-pref-key is always different than name.
        -- Note: if preferences are not managed, then depending on binding,
        -- app-get-pref may equal value immediately even before calling this method, in which case
        -- we must fall through to process changes.
        return
    end
    -- Note: preference key is different than name.
    Manager.propChangeHandlerMethod( self, props, name, value, call )
end



function ExtendedManager:sql( name )

    local testScript = "select * from AgLibraryCollection;"
--[[    local realScript_oneStepToggle_legacy = nil [ [
UPDATE adobe_imagedevelopsettings
   SET text =
          (SELECT hs1.text
             FROM adobe_libraryimagedevelophistorystep hs1
            WHERE hs1.image = adobe_imagedevelopsettings.image
              AND hs1.id_local =
                     (SELECT MAX (hs2.id_local)
                        FROM adobe_libraryimagedevelophistorystep hs2
                       WHERE hs2.image = adobe_imagedevelopsettings.image
                         AND hs2.id_global <>
                                  adobe_imagedevelopsettings.historysettingsid)),
       historysettingsid =
          (SELECT hs1.id_global
             FROM adobe_libraryimagedevelophistorystep hs1
            WHERE hs1.image = adobe_imagedevelopsettings.image
              AND hs1.id_local =
                     (SELECT MAX (hs2.id_local)
                        FROM adobe_libraryimagedevelophistorystep hs2
                       WHERE hs2.image = adobe_imagedevelopsettings.image
                         AND hs2.id_global <>
                                  adobe_imagedevelopsettings.historysettingsid)),
       digest = NULL
 WHERE image IN (SELECT ci.image
                   FROM aglibrarycollectionimage ci, aglibrarycollection c
                  WHERE c.id_local = ci.collection AND NAME LIKE 'ScrewAutoSync')
   AND (SELECT COUNT (*)
          FROM adobe_libraryimagedevelophistorystep
         WHERE image = adobe_imagedevelopsettings.image) > 1;--]]
         
   local realScript = [[
UPDATE adobe_imagedevelopsettings
   SET text =
          (SELECT hs1.text
             FROM adobe_libraryimagedevelophistorystep hs1
            WHERE hs1.image = adobe_imagedevelopsettings.image
              AND hs1.id_local =
                     (SELECT MAX (hs2.id_local)
                        FROM adobe_libraryimagedevelophistorystep hs2
                       WHERE hs2.image = adobe_imagedevelopsettings.image
                         AND hs2.dateCreated <
                               (SELECT dateCreated
                                  FROM adobe_libraryimagedevelophistorystep
                                 where id_global = adobe_imagedevelopsettings.historysettingsid))),
       historysettingsid =
          (SELECT hs1.id_global
             FROM adobe_libraryimagedevelophistorystep hs1
            WHERE hs1.image = adobe_imagedevelopsettings.image
              AND hs1.id_local =
                     (SELECT MAX (hs2.id_local)
                        FROM adobe_libraryimagedevelophistorystep hs2
                       WHERE hs2.image = adobe_imagedevelopsettings.image
                         AND hs2.dateCreated <
                               (SELECT dateCreated
                                  FROM adobe_libraryimagedevelophistorystep
                                 where id_global = adobe_imagedevelopsettings.historysettingsid))),
       digest =
           (SELECT hs1.digest
             FROM adobe_libraryimagedevelophistorystep hs1
            WHERE hs1.image = adobe_imagedevelopsettings.image
              AND hs1.id_local =
                     (SELECT MAX (hs2.id_local)
                        FROM adobe_libraryimagedevelophistorystep hs2
                       WHERE hs2.image = adobe_imagedevelopsettings.image
                         AND hs2.dateCreated <
                               (SELECT dateCreated
                                  FROM adobe_libraryimagedevelophistorystep
                                 where id_global = adobe_imagedevelopsettings.historysettingsid)))
WHERE image IN (SELECT ci.image
                   FROM aglibrarycollectionimage ci, aglibrarycollection c
                  WHERE c.id_local = ci.collection AND NAME LIKE 'ScrewAutoSync')
   AND (SELECT COUNT (*)
          FROM adobe_libraryimagedevelophistorystep
         WHERE image = adobe_imagedevelopsettings.image) > 1;]] -- dunno if the semi-colon is necessary, but doesn't hurt.

    local tempFile
    app:call( Service:new{ name=name, async=true, progress={ caption="Dialog box needs your attention..." }, main=function( call )
        local file
        repeat
		    file = dia:selectFile{
		        title = "Select .lrcat (catalog) file.",
		        fileTypes = { "lrcat" },
		    }
		    if not file then
		        call:cancel()
		        return
		    end
		    if file == catalog:getPath() then
		        app:show{ warning="Select a different catalog." }
		    else
		        break
		    end
        until false  
        local props = LrBinding.makePropertyTable( call.context )
        props.nSteps = 1
        local btn = app:show{ confirm="Are you sure you want to run SQL update script on this catalog: '^1'?",
            subs = { file },
            viewItems = { vf:row {
                vf:static_text {
                    title = "Enter number of history steps to roll back:",
                },
                vf:edit_field {
                    bind_to_object = props,
                    value = bind 'nSteps',
                    min = 1,
                    max = 999,
                    precision = 0,
                    width_in_digits = 4,
                },
            }},
            buttons = { dia:btn( "Yes - I created 'ScrewAutoSync' Collection in it", 'ok' ) },
        }
        if btn ~= 'ok' then
	        call:cancel()
	        return
	    end
        local nSteps = props.nSteps
        assert( type( nSteps ) == 'number', "should be number" )
        
        app:log( "User approved SQL update to be run on ^1 - ^2 steps back.", file, str:to( nSteps ) )
        
        local s, m = self.sqlite:isUsable()
        if s then
            if m then
                app:log( "SQLite may be usable: ^1", m )
            else
                app:log( "SQLite is usable" )
            end
        else
            app:logError( m )
            return
        end

        local function _sql( script, tempFile )
            
            local s, m = fso:writeFile( tempFile, script )
            if not s then
                error( m )
            else
                app:log( "SQL written to: ^1", tempFile )
            end
            local param = str:fmt( '"^1" ".read "^2""', file:gsub( "\\", "\\\\" ), tempFile:gsub( "\\", "\\\\" ) ) -- parameters are not quoted by command executor, but cat-path needs to be.
            --local param = str:fmtx( '^1 < ^2', file, tempFile ) -- works for test-script, but not real-script.
            local s, m, c = self.sqlite:executeCommand( param, nil, nil, 'get' )
            return s, m, c        
        end


        tempFile = LrPathUtils.getStandardFilePath( 'temp' )
        tempFile = LrPathUtils.child( tempFile, "sql.txt" )
        tempFile = LrFileUtils.chooseUniqueFileName( tempFile )
        local nRolled = 0
    
        local s, m, c = _sql( testScript, tempFile )
        if s then
            app:log( "Got collections from catalog." )
            if c:find( "ScrewAutoSync" ) then
                app:log( "Found ScrewAutoSync collection." )
            else
                app:logVerbose( c )
                app:logError( "ScrewAutoSync collection not found." )
                --app:show{ warning="SQLite executed OK, but no 'ScrewAutoSync' collection found." }
                return
            end
            
            --call:setCaption( "Please wait..." )
            for i = 1, nSteps do
                app:log( "Rolling back step ^1", i )
                call:setCaption( "Rolling back step ^1", i )
                local s, m, c = _sql( realScript, tempFile )
                if s then
                    app:log( "Got status." )
                end
                nRolled = nRolled + 1
                app:log( "No content returned, but none expected - not sure if it worked or not." )
                if call:isQuit() then
                    break
                else
                    call:setPortionComplete( i, nSteps )
                end
            end
            
            call:setCaption( "Dialog box needs your attention..." )
            app:show{ info="^1 supposedly rolled back - restart Lightroom and open '^2' to see.",
                subs = { str:nItems( nRolled, "history steps" ), file },
            }
            
        else
            app:logErr( m )
            -- app:show{ error="^1", m }
        end
        
    end, finale=function( call )
        if tempFile and fso:existsAsFile( tempFile ) then
            if app:isAdvDbgEna() then
                LrShell.revealInShell( tempFile )
            else
                LrFileUtils.delete( tempFile )
            end
        end
    end } )

end



--- Sections for bottom of plugin manager dialog.
-- 
function ExtendedManager:sectionsForBottomOfDialogMethod( vf, props)

    local appSection = {}
    if app.prefMgr then
        appSection.bind_to_object = props
    else
        appSection.bind_to_object = prefs
    end
    
	appSection.title = app:getAppName() .. " Settings"
	appSection.synopsis = bind{ key='presetName', object=prefs }

	appSection.spacing = vf:label_spacing()
	
    appSection[#appSection + 1] =
        vf:row {
            -- bind_to_object = props,
            vf:static_text {
                title = "SQLite App",
                width = share 'label_width',
            },
            vf:edit_field {
                value = app:getGlobalPrefBinding( 'sqliteApp' ),
				tooltip = "Path to sqlite app or executable, *** or leave blank to use built-in default (recommended). You can also enter a relative \"name\", if it's \"pathed/registered\" in the OS.",
                width_in_chars = 40,
            },
            vf:push_button {
                title = "Browse",
				tooltip = "Browse to sqlite app or executable, *** or leave blank to use built-in default (recommended).",
				action = function( button )
				    dia:selectFile( {
				        title = "SQLite3 App or Executable",
				    },
				    prefs,
				    app:getGlobalPrefKey( 'sqliteApp' )
				    )
				end,
                --width = share 'data_width',
            },
        }

    --[[
    appSection[#appSection + 1] =
        vf:row {
            -- bind_to_object = props,
            vf:push_button {
                title = "Test SQLite",
                width = share 'label_width',
				tooltip = "Test",
				action = function( button )
		            self:sql( button.title, "select * from AgLibraryCollection;", true )
				end,
			}
		}
	--]]
		
    appSection[#appSection + 1] =
        vf:row {
            -- bind_to_object = props,
            vf:push_button {
                title = "Screw Auto Sync",
				tooltip = "Issue test query, check for target collection, issue SQL update.",
				action = function( button )
				
				    self:sql( button.title )
				    
				end,
                width = share 'label_width',
            },
            vf:static_text {
                title = "Select catalog, do the deed.",
                --width = share 'label_width',
            },
        }

    appSection[#appSection + 1] =
        vf:row {
            -- bind_to_object = props,
            vf:push_button {
                title = "Help",
				-- tooltip = "Instructions...",
				action = function( button )
				    local m = {}
				    m[#m + 1] = "Instructions:"
				    m[#m + 1] = "0. Backup your catalog."
				    m[#m + 1] = "1. Make a collection called 'ScrewAutoSync' (no spaces) in root."
				    m[#m + 1] = "2. Put all affected images into the above-mentioned collection."
				    m[#m + 1] = "3. Count the number of adjustments you'll need to \"undo\", in the edit history list."
				    m[#m + 1] = "3. Restart Lightroom with a different catalog - any other catalog - empty catalog OK..."
				    m[#m + 1] = "4. Return here to plugin manager, and click 'Screw Auto Sync' button, then wait for a dialog box - once for each adjustment to \"undo\"."
				    m[#m + 1] = "5. Assuming it worked, restart Lightroom with hopefully unscrewed catalog - if all is well, delete 'ScrewAutoSync' collection. If it didn't work, consult the log file..."
				    dia:quickTips( m, true ) -- just 1 eol.
				end,
            width = share 'label_width',
            },
            vf:static_text {
                title = "Instructions...",
                --width = share 'label_width',
            },
        }

    if not app:isRelease() then
    	appSection[#appSection + 1] = vf:spacer{ height = 20 }
    	appSection[#appSection + 1] = vf:static_text{ title = 'For plugin author only below this line:' }
    	appSection[#appSection + 1] = vf:separator{ fill_horizontal = 1 }
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:edit_field {
    				value = bind( "testData" ),
    			},
    			vf:static_text {
    				title = str:format( "Test data" ),
    			},
    		}
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:push_button {
    				title = "Test",
    				action = function( button )
    				    app:call( Call:new{ name='Test', main = function( call )
                            app:show( { info="^1: ^2" }, str:to( app:getGlobalPref( 'presetName' ) or 'Default' ), app:getPref( 'testData' ) )
                        end } )
    				end
    			},
    			vf:static_text {
    				title = str:format( "Perform tests." ),
    			},
    		}
    end
		
    local sections = Manager.sectionsForBottomOfDialogMethod ( self, vf, props ) -- fetch base manager sections.
    if #appSection > 0 then
        tab:appendArray( sections, { appSection } ) -- put app-specific prefs after.
    end
    return sections
end



return ExtendedManager
-- the end.