local ui, uiu, uie = require("ui").quick()
local utils = require("utils")

local scene = {
	name = "CCModDB",
}

local function generateModColumns(self)
	local listcount = math.max(1, math.min(6, math.floor(love.graphics.getWidth() / 350)))
	if self.listcount == listcount then
		return nil
	end
	self.listcount = listcount

	local lists = {}
	for i = 1, listcount do
		lists[i] = uie.column({})
				:with({ style = { spacing = 2 }, cacheable = false })
				:with(uiu.fillWidth(1 / listcount + 1))
				:with(uiu.at((i == 1 and 0 or 1) + (i - 1) / listcount, 0))
				:as("mods" .. tostring(i))
	end

	return lists
end

local root = uie.column({
	uie
			.scrollbox(uie.column({
				uie
						.dynamic()
						:with({
							cacheable = false,
							generate = generateModColumns,
						})
						:with(uiu.fillWidth)
						:as("modColumns"),
			})
				:with({
					clip = false,
					cacheable = false,
				})
				:with(uiu.fillWidth))
			:with({
				style = { barPadding = 16 },
				clip = false,
				cacheable = false,
			})
			:with(uiu.fillWidth)
			:with(uiu.fillHeight(59))
			:with(uiu.at(0, 59)),

	uie.paneled
			.column({
				uie.group():with({
					height = 32,
				}),

				uie
						.row({
							uie
									.button(
										uie.row({
											uie.icon("browser"):with({ scale = 24 / 256 }),
											uie.label("Go to c2dl.info"):with({ y = 2 }),
										}),
										function()
											utils.openURL("https://c2dl.info/cc/mods")
										end
									)
									:as("openC2DLButton"),

							uie
									.row({
										uie
												.button(uie.icon("back"):with({ scale = 24 / 256 }), function()
													scene.loadPage(scene.page - 1)
												end)
												:as("pagePrev"),
										uie
												.label("Page #?", ui.fontBig)
												:with({
													y = 4,
												})
												:as("pageLabel"),
										uie
												.button(uie.icon("forward"):with({ scale = 24 / 256 }), function()
													scene.loadPage(scene.page + 1)
												end)
												:as("pageNext"),
									})
									:with({
										style = {
											spacing = 24,
										},
										cacheable = false,
										clip = false,
									}):hook({
										layoutLateLazy = function(orig, self)
											-- Always reflow this child whenever its parent gets reflowed.
											self:layoutLate()
											self:repaint()
										end,

										layoutLate = function(orig, self)
											orig(self)
											if scene.searchLast ~= "" then
												self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
												self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
											else
												local openC2DLButton = scene.root:findChild("openC2DLButton")
												local rightRow = scene.root:findChild("rightRow")
												local width = self.parent.innerWidth - openC2DLButton.width - rightRow.width
												self.x = math.floor(width * 0.5 - self.width * 0.5 + openC2DLButton.width)
												self.realX = math.floor(width * 0.5 - self.width * 0.5 + openC2DLButton.width)
											end
										end
									}),

							uie.row({
								uie.field(
									"",
									function(self, value, pref)
										if scene.loadPage and value == prev then
											scene.loadPage(value)
										end
									end
								):with({
									width = 200,
									height = 24,
									placeholder = "Search"
								}):as("searchBox"),

								uie.button(
									uie.icon("search"):with({ scale = 24 / 256 }),
									function()
										scene.loadPage(scene.root:findChild("searchBox").text)
									end
								):as("searchBtn")
							}):with({
								style = {
									spacing = 8
								},
								cacheable = false,
								clip = false
							}):with(uiu.rightbound):as("rightRow")
						})
						:with({
							cacheable = false,
							clip = false,
						})
						:with(uiu.fillWidth),
			})
			:with({
				style = {
					patch = "ui:patches/topbar",
					spacing = 0,
				},
			})
			:with(uiu.at(0, -32))
			:with(uiu.fillWidth),
}):with({
	style = { spacing = 2 },
	cacheable = false,
	_fullroot = true,
})
scene.root = root

return scene
