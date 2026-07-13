--!strict

local TweenService = game:GetService("TweenService")

local Tween = {}

export type TweenInfoLike = {
	Time: number?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
}

local function resolveTweenInfo(info: TweenInfoLike?): TweenInfo
	if info == nil then
		return TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	return TweenInfo.new(
		info.Time or 0.2,
		info.EasingStyle or Enum.EasingStyle.Quint,
		info.EasingDirection or Enum.EasingDirection.Out,
		info.RepeatCount or 0,
		info.Reverses or false,
		info.DelayTime or 0
	)
end

function Tween.Play(instance: Instance, properties: { [string]: any }, info: TweenInfoLike?): Tween
	local tween = TweenService:Create(instance, resolveTweenInfo(info), properties)
	tween:Play()
	return tween
end

function Tween.PlayAndWait(instance: Instance, properties: { [string]: any }, info: TweenInfoLike?)
	local tween = Tween.Play(instance, properties, info)
	tween.Completed:Wait()
end

return Tween
