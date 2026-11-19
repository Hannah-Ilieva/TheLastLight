-- MapKit: small building helpers shared by the map generator modules.
-- Everything created here gets the "Generated" attribute, so BuildMap can delete
-- and rebuild it safely without touching objects you added by hand.

local CollectionService = game:GetService("CollectionService")

local MapKit = {}

MapKit.GENERATED = "Generated"

-- Creates an anchored part from a table of Roblox property names.
-- Place it with either `CFrame`, or `Position` (+ optional `Orientation` in degrees,
-- like the Properties window). `Tag` adds a CollectionService tag.
function MapKit.part(spec, parent: Instance, className: string?): BasePart
	local part = Instance.new(className or "Part")
	part.Anchored = true
	if part:IsA("Part") then
		part.Shape = spec.Shape or Enum.PartType.Block -- set before Size so Size isn't adjusted afterwards
	end
	for key, value in spec do
		if key ~= "Position" and key ~= "Orientation" and key ~= "Shape" and key ~= "CFrame" and key ~= "Tag" then
			part[key] = value
		end
	end
	if spec.CFrame then
		part.CFrame = spec.CFrame
	else
		local o = spec.Orientation or Vector3.zero
		part.CFrame = CFrame.new(spec.Position) * CFrame.fromOrientation(math.rad(o.X), math.rad(o.Y), math.rad(o.Z))
	end
	if spec.Tag then
		CollectionService:AddTag(part, spec.Tag)
	end
	part:SetAttribute(MapKit.GENERATED, true)
	part.Parent = parent
	return part
end

-- Copies `look` and adds the extra fields, so one "look" table can be reused.
function MapKit.with(look, extra)
	local spec = table.clone(look)
	for key, value in extra do
		spec[key] = value
	end
	return spec
end

-- A flat round disc lying on the ground. A cylinder's length runs along X, so
-- tilting it 90 degrees on Z lays it flat and Size.X becomes its thickness.
function MapKit.disc(name: string, center: Vector3, diameter: number, thickness: number, look, parent: Instance): BasePart
	return MapKit.part(MapKit.with(look, {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(thickness, diameter, diameter),
		Position = center,
		Orientation = Vector3.new(0, 0, 90),
	}), parent)
end

-- A cylinder ("limb") running from one point to another: trunks, branches, antlers, roots.
function MapKit.limb(name: string, from: Vector3, to: Vector3, thickness: number, look, parent: Instance): BasePart
	local middle = (from + to) / 2
	-- lookAt points -Z along the limb; turning 90 degrees on Y lines the cylinder's X axis up with it.
	local cframe = CFrame.lookAt(middle, to) * CFrame.Angles(0, math.pi / 2, 0)
	return MapKit.part(MapKit.with(look, {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new((to - from).Magnitude, thickness, thickness),
		CFrame = cframe,
	}), parent)
end

-- A four-sided pyramid made of four corner wedges, standing on `baseCenter`.
-- Used for the layers of the pine trees. `yaw` turns it (radians).
function MapKit.pyramid(name: string, baseCenter: Vector3, base: number, height: number, yaw: number, look, parent: Instance)
	local origin = CFrame.new(baseCenter) * CFrame.Angles(0, yaw, 0)
	for quarter = 0, 3 do
		-- A corner wedge's peak is at its (+X, -Z) top corner; this offset puts that
		-- corner at the middle of the pyramid, then each copy is turned 90 degrees.
		local cframe = origin * CFrame.Angles(0, quarter * math.pi / 2, 0) * CFrame.new(-base / 4, height / 2, base / 4)
		MapKit.part(MapKit.with(look, {
			Name = name,
			Size = Vector3.new(base / 2, height, base / 2),
			CFrame = cframe,
		}), parent, "CornerWedgePart")
	end
end

-- A generated Model. `persistent` keeps it loaded on every client (needed for lamps).
function MapKit.model(name: string, parent: Instance, persistent: boolean?): Model
	local model = Instance.new("Model")
	model.Name = name
	if persistent then
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end
	model:SetAttribute(MapKit.GENERATED, true)
	model.Parent = parent
	return model
end

-- Finds a folder by name, or creates it. Folders are never deleted, so anything
-- you put inside them is safe.
function MapKit.folder(parent: Instance, name: string): Folder
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

function MapKit.clearGenerated(container: Instance)
	for _, item in container:GetDescendants() do
		if item.Parent and item:GetAttribute(MapKit.GENERATED) then
			item:Destroy()
		end
	end
end

-- Adds a light, particle emitter or sound to a part. `props` sets its properties.
function MapKit.add(className: string, props, parent: Instance): Instance
	local item = Instance.new(className)
	for key, value in props do
		item[key] = value
	end
	item.Parent = parent
	return item
end

return MapKit
