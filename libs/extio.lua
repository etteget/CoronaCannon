--[[

#Functions added to io library

]]--

local io = require("io")
local lfs = require("lfs")
--
-- Returns the file names of the given path.
--
-- path - "raw" path, i.e. get path by:
--        local path = system.pathForFile("res/defaultTiled", system.ResourceDirectory )
-- extension - if extension is given, returns only the names with given extension
--
-- NOTE: returns both folders and files.
-- NOTE: does not return "." and ".." directories.
--
io.getFiles = function(path, extension)
  local files = {}

  -- lfs.dir returns file name string
  for fileName in lfs.dir( path ) do
    local toAdd =
      ("." ~= fileName) and
      (".." ~= fileName) and
      (extension and string.ends(fileName, extension) or not extension)
    if toAdd then
      table.insert(files, fileName)
    end
  end

  return files
end

--
-- Returns the names of the folders in given path.
-- Path is a string, for example "images/ammo"
--
io.getFolders = function(path)
  local files = io.getFiles(path)
  local dirNames = {}

  for _, fileName in ipairs(files) do
    local fileAttributes = lfs.attributes (path .. "/" .. fileName)
    if (fileAttributes and fileAttributes.mode == "directory") then
      table.insert(dirNames, fileName)
    end
  end

  return dirNames
end