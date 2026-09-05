/*
**
**  This software is provided 'as-is', without any express or implied
**  warranty.  In no event will the authors be held liable for any damages
**  arising from the use of this software.
**
**  Permission is granted to anyone to use this software for any purpose,
**  including commercial applications, and to alter it and redistribute it
**  freely, subject to the following restrictions:
**
**  1. The origin of this software must not be misrepresented; you must not
**     claim that you wrote the original software. If you use this software
**     in a product, an acknowledgment in the product documentation would be
**     appreciated but is not required.
**  2. Altered source versions must be plainly marked as such, and must not be
**     misrepresented as being the original software.
**  3. This notice may not be removed or altered from any source distribution.
**
**  Note: Some of the libraries UICore may link to may have additional
**  requirements or restrictions.
**
**  Based on the paper "Fast Half Float Conversions" by Jeroen van der Zijp.
*/

#pragma once

/// Convert half-float to float. Only works for 'normal' half-float values
inline float halfToFloatSimple(unsigned short hf)
{
	unsigned int float_value = ((hf & 0x8000) << 16) | (((hf & 0x7c00) + 0x1C000) << 13) | ((hf & 0x03FF) << 13);
	void *ptr = static_cast<void*>(&float_value);
	return *static_cast<float*>(ptr);
}
