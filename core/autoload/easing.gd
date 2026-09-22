@tool
extends Node

# WORST CODE EVER MADE??????

const linear := 1.0

const quadIn := 2.0
const quadOut := 0.5
const quadInOut := -2.0

const cubeIn := 3.0
const cubeOut := 1.0 / 3.0
const cubeInOut := -3.0

const quartIn := 4.0
const quartOut := 0.25
const quartInOut := -4.0

const quintIn := 5.0
const quintOut := 0.2
const quintInOut := -5.0

const sineIn := 1.75
const sineOut := 0.57135
const sineInOut := -1.75035

const expoIn := 6.199
const expoOut := 0.1613
const expoInOut := -6.19846

const circIn := 3.781
const circOut := 0.2645
const circInOut := -3.78032

const smooth := -1.6521

func from_string(e: String) -> float:
	if e in self:
		return self.get(e)
	return expoOut
