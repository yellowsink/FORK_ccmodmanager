local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local alert = require("alert")
local threader = require("threader")
local sharp      = require("sharp")

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

local root = uie.column({
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
	print(sharp.testCrap("hi"):result())
end

return scene
