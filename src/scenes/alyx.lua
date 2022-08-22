local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local alert = require("alert")
local threader = require("threader")
local sharp = require("sharp")
local config = require("config")
local scener = require("scener")

local scene = {
	name = "Alyxia's Testing Grounds",
}

local function newsEntry(data)
	if not data then
		return nil
	end

	local item = uie.column({
		data.title and uie.label(data.title, ui.fontMedium),

		data.image and uie.group({
			uie.spinner():with({ time = love.math.random() }),
		}):as("imgholder"),

		data.preview and uie.label(data.preview):with({ wrap = true }),

		uie
			.row({
				data.link and uie.button(
					uie.row({
						uie.icon("browser"):with({ scale = 24 / 256 }),
						uie.label(data.linktext or "Open in browser"):with({ y = 2 }),
					}),
					function()
						utils.openURL(data.link)
					end
				),

				data.text and uie.button(uie.icon("article"):with({ scale = 24 / 256 }), function()
					alert({
						title = data.title,
						body = uie.label(data.text),
						butons = data.link and {
							{
								"Open in browser",
								function()
									utils.openURL(data.link)
								end,
							},
							{ "Close" },
						} or { { "Close" } },
					})
				end),
			})
			:with({
				clip = false,
			})
			:with(uiu.rightbound),
	}):with(uiu.fillWidth)

	return item
end

function scene.createInstalls()
	return uie.paneled
		.column({
			uie.label("Installations", ui.fontBig),

			uie
				.column({
					uie
						.scrollbox(uie.list({}, function(self, data)
							config.install = data.index
							config.save()
						end)
							:with({
								grow = false,
							})
							:with(uiu.fillWidth)
							:as("installs"))
						:with(uiu.fillWidth)
						:with(uiu.fillHeight(true)),

					uie
						.row({
							uie
								.group({
									uie
										.label({ { 1, 1, 1, 0.5 }, "main menu broke, please fix." })
										:with({
											y = 8,
										})
										:with(uiu.rightbound)
										:as("installcount"),
								})
								:with(uiu.fillWidth(true)),
							uie
								.button("Manage", function()
									scener.push("installmanager")
								end)
								:with({
									clip = false,
									cacheable = false,
								})
								:with(utils.important(24, function()
									return #config.installs == 0
								end))
								:with(uiu.rightbound),
						})
						:with({
							clip = false,
						})
						:with(uiu.bottombound)
						:with(uiu.fillWidth),
				})
				:with({ clip = false })
				:with(uiu.fillWidth)
				:with(uiu.fillHeight(true)),
		})
		:with({ width = 256 })
		:with(uiu.fillHeight)
end

function scene.reloadInstalls(scene, cb)
	local list, counter = scene.root:findChild("installs", "installcount")
	list.children = {}
	counter.text = { { 1, 1, 1, 0.5 }, "Scanning..." }

	local installs = config.installs

	local function handleFound(task, all)
		local new = #all
		for i = 1, #all do
			local found = all[i]
			for j = 1, #installs do
				local existing = installs[j]
				if found.path == existing.path then
					new = new - 1
					break
				end
			end
		end

		if new == 0 then
			counter.text = ""
		else
			counter.text = { { 1, 1, 1, 0.5 }, uiu.countformat(new, "%d new install found.", "%d new installs found.") }
		end
	end

	local foundCached = require("finder").getCached()
	if foundCached then
		handleFound(nil, foundCached)
	else
		threader.wrap("finder").findAll():calls(handleFound)
	end

	for i = 1, #installs do
		local entry = installs[i]
		local item = uie.listItem(
			{ { 1, 1, 1, 1 }, entry.name, { 1, 1, 1, 0.5 }, "\nScanning..." },
			{ index = i, entry = entry, version = "???" }
		)

		sharp.getVersionString(entry.path):calls(function(t, version)
			version = version or "???"

			local crosscode, ccloader
			if version and version:sub(1, 4) ~= "? - " then
				crosscode = version:match("CrossCode ([^ ]+)")
				ccloader = version:match("CCLoader ([^ ]+)")
				if crosscode and ccloader then
					version = crosscode .. " + " .. ccloader
				else
					version = crosscode or version
				end
			end

			item.text = { { 1, 1, 1, 1 }, entry.name, { 1, 1, 1, 0.5 }, "\n" .. version }
			item.data.version = version
			item.data.versionCrossCode = crosscode
			item.data.versionCCLoader = ccloader
			if cb and item.data.index == config.install then
				cb(item.data)
			end
		end)

		list:addChild(item)
	end

	if #installs == 0 then
		list:addChild(uie.group({
			uie.label([[
Your CrossCode install list is empty.
Press the manage button below.]]),
		}):with({
			style = {
				padding = 8,
			},
		}))
	end

	list.selected = list.children[config.install or 1] or list.children[1] or false
	list:reflow()

	if cb then
		cb()
	end
end

local root = uie.column({
	uie.paneled
		.column({

			uie
				.row({
					scene.createInstalls(),
				})
				:with({
					clip = false,
				})
				:with(uiu.fillWidth)
				:with(uiu.fillHeight(true)),
		})
		:hook({
			layoutLateLazy = function(orig, self)
				-- Always reflow this child whenever its parent gets reflowed.
				self:layoutLate()
				self:repaint()
			end,

			layoutLate = function(orig, self)
				orig(self)
				local style = self.style
				style.bg = nil
				local boxBG = style.bg
				style.bg = { boxBG[1], boxBG[2], boxBG[3], 0.6 }
			end,
		})
		:with(uiu.fillWidth(true))
		:with(uiu.fillHeight),
	uie.paneled
		.column({
			uie.label("News", ui.fontBig),
			uie
				.scrollbox(uie.column({
					newsEntry({
						preview = "News machine broke, please fix.",
					}),
				})
					:with({
						style = {
							spacing = 16,
						},
						clip = false,
					})
					:with(uiu.fillWidth)
					:as("newsfeed"))
				:with({
					clip = true,
					clipPadding = { 8, 4, 8, 8 },
					cachePadding = { 8, 4, 8, 8 },
				})
				:with(uiu.fillWidth)
				:with(uiu.fillHeight(true)),
		})
		:with({
			width = 256,
		})
		:with(uiu.fillHeight)
		:with(uiu.rightbound),
})

scene.root = root

scene.installs = root:findChild("installs")
scene.installs:hook({
	cb = function(orig, self, data)
		orig(self, data)
		scene.updateMainList(data)
	end,
})

function scene.updateMainList(install)
	ui.runOnce(function(config, scene, install)
		if not install and #config.installs ~= 0 then
			return
		end
	end, config, scene, install)
end

function scene.load()
	threader.routine(function()
		local newsfeed = scene.root:findChild("newsfeed")

		newsfeed.children = {}
		newsfeed:addChild(uie.row({
			uie.label("Loading"),
			uie
				.spinner()
				:with({
					width = 16,
					height = 16,
				})
				:with(uiu.rightbound),
		})
			:with({
				clip = false,
				cacheable = false,
			})
			:with(uiu.fillWidth))

		local all = threader
			.run(function()
				local utils = require("utils")
				local list, err = utils.download("https://c2dl.info/cc/news/feed")
				if not list then
					print("failed fetching news rss feed")
					print(err)
					return {
						{
							error = true,
							preview = "CCModManager failed fetching the news feed.",
						},
					}
				end

				local feed = utils.fromXML(list).feed

				local all = {}

				for i = 1, #feed.entry do
					all[#all + 1] = feed.entry[i]
				end

				table.sort(all, function(a, b)
					return b.updated < a.updated
				end)

				for i = 1, #all do
					local item = all[i]
					local data = {}

					data.title = item.title

					if string.len(item.title) > 22 then
						local trimmed = string.sub(item.title, 1, 21) .. "…"
						data.title = trimmed
					end

					data.preview = item.summary
					data.link = item.id

					all[i] = data
				end

				return all
			end)
			:result()

		scene.news = all

		newsfeed.children = {}

		for i = 1, #all do
			newsfeed:addChild(newsEntry(all[i]))
		end
	end)
end

function scene.enter()
	scene.reloadInstalls(scene, scene.updateMainList)
	print(sharp.testCrap("hi"):result())
end

return scene
