local ui, uiu, uie = require("ui").quick()
local alert = require("alert")
local utils = require("utils")
local threader = require("threader")
local modinstaller = require("modinstaller")

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
							layoutLateLazy = function(_, self)
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
							function(_, value, prev)
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

scene.cache = {}

scene.searchLast = ""


function scene.loadPage(page)
	if scene.loadingPage then
		return scene.loadingPage
	end

	page = page or scene.page
	if scene.searchLast == page then
		return threader.routine(function() end)
	end

	if page == "" then
		scene.searchLast = ""
		page = scene.page
	end

	scene.loadingPage = threader.routine(function()
		local lists, pagePrev, pageLabel, pageNext = root:findChild("modColumns", "pagePrev", "pageLabel", "pageNext")

		local errorPrev = root:findChild("error")
		if errorPrev then
			errorPrev:removeSelf()
		end

		local isQuery = type(page) == "string"

		if not isQuery then
			scene.searchLast = ""
			if page < 0 then
				page = 0
			end
		end

		lists.all = {}

		pagePrev.enabled = false
		pageNext.enabled = false
		pagePrev:reflow()
		pageNext:reflow()

		if not isQuery then
			if page == 0 then
				pageLabel.text = "Featured"
			else
				pageLabel.text = "Page #" .. tostring(page)
			end
			scene.page = page
		else
			pageLabel.text = page
			scene.searchLast = page
		end

		local loading = uie.paneled.row({
			uie.label("Loading"),
			uie.spinner():with({
				width = 16,
				height = 16
			})
		}):with({
			clip = false,
			cacheable = false
		}):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
		scene.root:addChild(loading)

		local entries, entriesError
		if not isQuery then
			entries, entriesError = scene.downloadFeaturedEntries()
		else
			entries, entriesError = scene.downloadSearchEntries(page)
		end

		if not entries then
			loading:removeSelf()
			root:addChild(uie.paneled.row({
				uie.label("Error downloading mod list: " .. tostring(entriesError))
			}):with({
				clip = false,
				cacheable = false
			}):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("error"))
			scene.loadingPage = nil
			pagePrev.enabled = not isQuery and page > 0 and
				((scene.sort == "latest" and scene.itemtypeFilter.filtervalue == "") or page > 1)
			pageNext.enabled = not isQuery
			pagePrev:reflow()
			pageNext:reflow()
			return
		end

		for _, value in pairs(entries) do
			if value.metadata.name == 'ccloader' or
				value.metadata.name == 'Simplify' or
				value.metadata.name == 'CCLoader display version' then
				goto next
			end
			lists.next:addChild(scene.item(value))
			::next::
		end

		loading:removeSelf()
		scene.loadingPage = nil
		-- "Featured" should be inaccessible if there is a sort or a filter
		pagePrev.enabled = not isQuery and page > 0 and
			((scene.sort == "latest" and scene.itemtypeFilter.filtervalue == "") or page > 1)
		pageNext.enabled = not isQuery
		pagePrev:reflow()
		pageNext:reflow()
	end)

	return scene.loadingPage
end

function scene.load()
	scene.loadPage(0)
end

function scene.downloadFeaturedEntries()
	local url = "https://github.com/CCDirectLink/CCModDB/raw/master/npDatabase.json"
	local data = scene.cache[url]
	if data ~= nil then
		return data
	end

	local msg
	data, msg = threader.wrap("utils").downloadJSON(url):result()
	if data then
		scene.cache[url] = data
	end

	return data, msg
end

-- TODO: Implement filtering the table based on `query`
-- possible because the `index` of the table is also the `metadata.name`
function scene.downloadSearchEntries(query)
	local url = "https://github.com/CCDirectLink/CCModDB/raw/master/npDatabase.json"
	local interData = scene.cache[url]
	local msg
	if interData == nil then
		interData, msg = scene.downloadFeaturedEntries()
	end

	local retdata = {}
	for key, value in pairs(interData) do
		if key:match(query) then
			retdata[key] = value
		end
	end

	return retdata, msg
end

-- TODO: Implement UI
function scene.item(mod)
	local name = mod.metadata.name
	local description = mod.metadata.description
	local version = mod.metadata.version
	local website = mod.metadata.homepage

	local item = uie.group({
		uie.group({}):with({
			clip = false,
			cacheable = false
		}):with(uiu.fill):as("bgholder"),

		uie.panel({}):hook({
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
				-- FIXME: blur is very taxing!
				style.bg = { boxBG[1], boxBG[2], boxBG[3], 0.95 }
			end
		}):with({
			style = {
				padding = 0,
				radius = 0,
				patch = false
			},
			clip = false,
			cacheable = false
		}):with(uiu.fill):as("bgdarken"),

		uie.group({
			uie.column({
				uie.column({
					uie.column({
						uie.label({ { 1, 1, 1, 1 }, name, { 1, 1, 1, 0.5 }, "\n" .. version }):as("title"),

						description and #description ~= 0 and uie.label(description):with({ wrap = true }):as("description")
					}):with({
						clip = false,
						cacheable = false
					}):with(uiu.fillWidth),

					uie.row({
						website and uie.button(
							uie.icon("browser"):with({ scale = 24 / 256 }),
							function()
								utils.openURL(website)
							end
						),

						uie.buttonGreen(
							uie.icon("download"):with({ scale = 24 / 256 }),
							function()
								local btns = {}

								for _, install in ipairs(mod.installation) do
									btns[#btns + 1] = install
								end

								for i = 1, #btns do
									local install = btns[i]
									local iName = utils.split(install.url, "/", true)
									btns[i] = uie[i == 1 and "buttonGreen" or "button"](
										{ { 1, 1, 1, 1 }, iName[#iName] },
										function()
											print("Want to install " .. install.url)
											self:getParent("container"):close("OK")
										end
									)
								end

								if #btns == 0 then
									return
								end

								alert({
									title = name,
									body = uie.scrollbox(uie.column(btns)),
									init = function(container)
										btns[#btns + 1] = uie.button("Close", function()
											container:close("Close")
										end)
										container:findChild("buttons"):removeSelf()

										local body = container:findChild("body")

										if #btns < 6 then
											body:with({
												calcSize = uie.group.calcSize
											})
											container:hook({
												awake = function(orig, self)
													orig(self)
													self:layoutLazy()
													self:layoutLateLazy()
													if self:findChild("title").width > body.width then
														body:with(uiu.fillWidth)
														local el = body.children[1]
														el:with(uiu.fillWidth)
														local children = el.children
														for i = 1, #children do
															children[i]:with(uiu.fillWidth)
														end
													else
														local el = body.children[i]
														local children = el.children
														local widest = 0
														for i = 1, #children do
															local width = children[i].width
															if width > widest then
																widest = width
															end
														end
														for i = 1, #children do
															if children[i].width < widest then
																children[i]:with(uiu.fillWidth):reflow()
															end
														end
													end
													self:reflowDown()
													self:reflow()
												end
											})
										else
											body:with(uiu.fillWidth):with(uiu.fillHeight(true))
											local el = body.children[1]
											el:with(uiu.fillWidth)
											local children = el.children
											for i = 1, #children do
												children[i]:with(uiu.fillWidth)
												children[i].label.wrap = true
											end
											container:findChild("box"):with({
												width = 800
											}):with(uiu.fillHeight(64))
										end
									end
								})
							end
						):with({
							clip = false,
							cacheable = false
						})
					}):with({
						clip = false,
						cacheable = false
					}):with(uiu.rightbound)
				}):with({
					clip = false,
					cacheable = false
				}):with(uiu.fillWidth)
			}):with({
				clip = false,
				cacheable = false
			}):with(uiu.fillWidth):as("content")
		}):with({
			style = {
				padding = 16
			},
			clip = false,
			cacheable = false
		}):with(uiu.fillWidth)
	}):with({
		cacheForce = true,
		cachePadding = 0,
		clip = false,
		cacheable = false
	}):with(uiu.fillWidth)

	return item
end

return scene
