local ui, uiu, uie = require("ui").quick()
local scener = require("scener")
local utils = require("utils")
local alert = require("alert")
local threader = require("threader")
local alyx = scener.preload("alyx")
require("love.system")

local scene = {
	name = "CCLoader Installer",
}

local root = uie.column({
	uie.row({
		alyx.createInstalls(),

		uie.paneled
			.column({
				uie.label("Versions", ui.fontBig),
				uie
					.panel({
						uie.label({
							{ 1, 1, 1, 1 },
							[[Use the newest version for more features and bugfixes.
Use the latest ]],
							{ 0.3, 0.8, 0.5, 1 },
							"stable",
							{ 1, 1, 1, 1 },
							" or ",
							{ 0.8, 0.7, 0.3, 1 },
							"beta",
							{ 1, 1, 1, 1 },
							[[ version if you hate updating.]],
						}),
					})
					:with({
						style = {
							patch = false,
						},
					})
					:with(uiu.fillWidth),

				uie
					.column({

						uie
							.scrollbox(uie.list({})
								:with({
									grow = false,
								})
								:with(uiu.fillWidth)
								:with(function(list)
									list.selected = list.children[1] or false
								end)
								:as("versions"))
							:with(uiu.fill),

						uie.paneled
							.row({
								uie.label("Loading"),
								uie.spinner():with({
									width = 16,
									height = 16,
								}),
							})
							:with({
								clip = false,
								cacheable = false,
							})
							:with(uiu.bottombound)
							:with(uiu.rightbound)
							:as("loadingVersions"),
					})
					:with({
						clip = false,
					})
					:with(uiu.fillWidth)
					:with(uiu.fillHeight(true))
					:as("versionsParent"),
			})
			:with(uiu.fillWidth(true))
			:with(uiu.fillHeight),
	})
		:with({ clip = false })
		:with(uiu.fillWidth)
		:with(uiu.fillHeight(true)),

	uie
		.row({
			uie
				.buttonGreen(
					uie
						.row({ uie.icon("download"):with({ scale = 21 / 256 }), uie.label("Install") })
						:with({ clip = false, cacheable = false })
						:with(uiu.styleDeep),
					function()
						scene.install()
					end
				)
				:hook({
					update = function(orig, self, ...)
						local root = scene.root
						local selected = root:findChild("installs").selected
						selected = selected and selected.data
						selected = selected and selected.version
						self.enabled = selected and root:findChild("versions").selected
						self.text = (selected and selected:match("%+")) and "Update" or "Install"
						orig(self, ...)
					end,
				})
				:with({
					clip = false,
					cacheable = false,
				})
				:with(uiu.fillWidth(true))
				:with(utils.important(24, function(self)
					return self.parent.enabled
				end))
				:as("install"),
			uie
				.button("Uninstall", function()
					alert({
						force = true,
						body = [[
	Uninstalling CCLoader will keep all your mods intact,
	unless you manually delete them, or fully reinstall CrossCode,

	If even uninstalling CCLoader doesn't bring the expected result,
	please go to your game manager's library and let if verify the game's files.
	Steam and the itch.io app let you do that without a full reinstall.]],
						buttons = {
							{
								"Uninstall anyway",
								function(container)
									scene.uninstall()
									container:close("OK")
								end,
							},
							{ "Keep CCLoader" },
						},
					})
				end)
				:hook({
					update = function(orig, self, ...)
						local root = scene.root
						local selected = root:findChild("installs").selected
						selected = selected and selected.data
						selected = selected and selected.version
						selected = selected and selected:match("%+")
						self.enabled = selected
						orig(self, ...)
					end,
				})
				:with(uiu.rightbound)
				:as("uninstall"),
		})
		:with({ clip = false })
		:with(uiu.fillWidth)
		:with(uiu.bottombound),
})
scene.root = root

function scene.install()
	if scene.installing then
		return scene.installing
	end

	scene.installing = threader.routine(function()
		local install = root:findChild("installs").selected
		install = install and install.data

		local version = root:findChild("versions").selected
		version = version and version.data

		if not install or not version then
			scene.installing = nil
			return
		end

		local installer = scener.push("installer")
		installer.onLeave = function()
			scene.installing = nil
		end

		local url
		if version == "manual" then
			installer.update("Select your CCLoader .zip file", false, "")

			local path = fs.openDialog("zip"):result()
			if not path then
				installer.update("Installation canceled", 1, "error")
				installer.done(false, {
					{
						"Retry",
						function()
							scener.pop()
							scene.install()
						end,
					},
					{
						"OK",
						function()
							scener.pop()
						end,
					},
				})
				return
			end

			url = "file://" .. path
		else
			installer.update(string.format("Preparing installation of CCLoader %s", version.version), false, "")
			url = version.buildURL
		end

		installer
			.sharpTask("installCCLoader", install.entry.path, url, string.sub(version.sha, 1, 7))
			:calls(function(task, last)
				if not last then
					return
				end

				if version == "manual" then
					installer.update("CCLoader successfully installed", 1, "done")
				else
					installer.update(string.format("CCLoader %s successfully installed", version.version), 1, "done")
				end
				installer.done({
					{
						"Launch",
						function()
							utils.launch(install.entry.path)
							scener.pop(2)
						end,
					},
					{
						"OK",
						function()
							scener.pop(2)
						end,
					},
				})
			end)
	end)

	return scene.installing
end

function scene.load()
	threader.routine(function()
		local utilsAsync = threader.wrap("utils")
		local releasesTask = utilsAsync.downloadJSON("https://api.github.com/repos/CCDirectLink/CCLoader/releases")
		local tagsTask = utilsAsync.downloadJSON("https://api.github.com/repos/CCDirectlink/CCLoader/tags")
		-- local commitsTask = utilsAsync.downloadJSON("https://api.github.com/repos/CCDirectLink/CCLoader/commits")

		local list = root:findChild("versions")

		local manualItem = uie.listItem("Select .zip from disk", "manual"):with(uiu.fillWidth)

		local releases, releasesError = releasesTask:result()
		if not releases then
			root:findChild("loadingVersions"):removeSelf()
			root:findChild("versionsParent"):addChild(uie.paneled
				.row({
					uie.label("Error downloading builds list: " .. tostring(releasesError)),
				})
				:with({
					clip = false,
					cacheable = false,
				})
				:with(uiu.bottombound)
				:with(uiu.rightbound)
				:as("error"))
			list:addChild(manualItem)
			return
		end

		local tags, tagsError = tagsTask:result()
		if not tags then
			root:findChild("loadingVersions"):removeSelf()
			root:findChild("versionsParent"):addChild(uie.paneled
				.row({
					uie.label("Error downloading tags list: " .. tostring(tagsError)),
				})
				:with({
					clip = false,
					cacheable = false,
				})
				:with(uiu.bottombound)
				:with(uiu.rightbound)
				:as("error"))
			list:addChild(manualItem)
			return
		end

		-- local commits, commitsError = commitsTask:result()
		-- if not commits then
		-- 	root:findChild("versionsParent"):addChild(uie.paneled
		-- 		.row({
		-- 			uie.label("Error downloading commits list: " .. tostring(commitsError)),
		-- 		})
		-- 		:with({ clip = false, cacheable = false })
		-- 		:with(uiu.bottombound)
		-- 		:with(uiu.rightbound)
		-- 		:as("error"))
		-- end

		local firstStable
		local pinSpacer

		for ri = 1, #releases do
			local release = releases[ri]
			local version = utils.split(release.tag_name, "/", true)[1]

			for _, tag in ipairs(tags) do
				if release.tag_name == tag.name then
					release.sha = tag.commit.sha
				end
			end

			local text = {}
			local info = ""

			local time = release.published_at
			if time then
				info = info .. " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", utils.dateToTimestamp(time))
			end

			if #info ~= 0 then
				text = { { 1, 1, 1, 1 }, version, { 1, 1, 1, 0.5 }, info }
			end

			release.version = version
			release.buildURL = release.zipball_url

			local pin = false

			::readd::

			local item = uie.listItem(text, release):with(uiu.fillWidth)
			item.label.wrap = true

			local index = nil

			if not firstStable then
				firstStable = item
				index = 1
			end

			if index then
				if not pinSpacer then
					pinSpacer = true
					list:addChild(
						uie
							.row({
								uie.label("All Versions"),
							})
							:with({
								style = {
									padding = 4,
								},
							}),
						1
					)
					list:addChild(
						uie
							.row({
								uie.icon("pin"):with({
									scale = 16 / 256,
									y = 2,
								}),
								uie.label("Pinned"),
							})
							:with({
								style = {
									padding = 4,
								},
							}),
						1
					)
				end

				index = index + 1
				pin = true
			end

			if pin then
				item:addChild(
					uie.icon("pin"):with({
						scale = 16 / 256,
						y = 2,
					}),
					1
				)
			end

			list:addChild(item, index)
			if index then
				goto readd
			end
		end

		root:findChild("loadingVersions"):removeSelf()
		list:addChild(manualItem)
	end)
end

function scene.enter()
	alyx.reloadInstalls(scene)
end

return scene
