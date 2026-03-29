import SwiftUI

enum HabitIconColor: String, CaseIterable, Codable {
    // MARK: - Basic Colors
    case primary, red, orange, yellow, mint, green, blue, purple
    case pink, brown, gray, softLavender, sky, coral, bluePink, oceanBlue
    case antarctica, sweetMorning, lusciousLime, celestial, yellowOrange, cloudBurst, candy, colorPicker
    case fitnessRed, fitnessGreen, fitnessBlue
    
    var color: Color {
        switch self {
        case .primary: .primary
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .mint: .mint
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .softLavender: .purple
        case .pink: .pink
        case .sky: .cyan
        case .brown: .brown
        case .gray: .gray
        case .colorPicker: .gray
        case .coral: .orange
        case .bluePink: .blue
        case .oceanBlue: .blue
        case .antarctica: .teal
        case .sweetMorning: .red
        case .lusciousLime: .mint
        case .celestial: .gray
        case .yellowOrange: .orange
        case .cloudBurst: .cyan
        case .candy: .pink
        case .fitnessRed: .red
        case .fitnessGreen: .green
        case .fitnessBlue: .blue
        }
    }
}

extension HabitIconColor {
    
    private var colorPair: (dark: Color, light: Color) {
        switch self {
        case .primary:
            (.primaryDark, .primaryLight)
        case .red:
            (Color(#colorLiteral(red: 0.8666666667, green: 0.3411764706, blue: 0.3176470588, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.3843137255, blue: 0.3607843137, alpha: 1)))
        case .orange:
            (Color(#colorLiteral(red: 0.9411764706, green: 0.6039215686, blue: 0.2156862745, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.6666666667, blue: 0.2549019608, alpha: 1)))
        case .yellow:
            (Color(#colorLiteral(red: 0.8745098039, green: 0.6745098039, blue: 0.2274509804, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.7843137255, blue: 0.3215686275, alpha: 1)))
        case .mint:
            (Color(#colorLiteral(red: 0, green: 0.5976608396, blue: 0.5107415318, alpha: 1)), Color(#colorLiteral(red: 0.3568627451, green: 0.7490196078, blue: 0.6666666667, alpha: 1)))
        case .green:
            (Color(#colorLiteral(red: 0.1992103457, green: 0.8570511937, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.6870413423, green: 0.9882482886, blue: 0.002495098161, alpha: 1)))
        case .blue:
            (Color(#colorLiteral(red: 0.4078431373, green: 0.5137254902, blue: 0.6431372549, alpha: 1)), Color(#colorLiteral(red: 0.5759755351, green: 0.7276879812, blue: 0.9165820313, alpha: 1)))
        case .purple:
            (Color(#colorLiteral(red: 0.4705882353, green: 0.4509803922, blue: 0.8078431373, alpha: 1)), Color(#colorLiteral(red: 0.6274509804, green: 0.5527653279, blue: 1, alpha: 1)))
        case .softLavender:
            (Color(#colorLiteral(red: 0.6784313725, green: 0.6431372549, blue: 0.8980392157, alpha: 1)), Color(#colorLiteral(red: 0.8039215686, green: 0.7764705882, blue: 1, alpha: 1)))
        case .pink:
            (Color(#colorLiteral(red: 0.7490196078, green: 0.4784313725, blue: 0.7215686275, alpha: 1)), Color(#colorLiteral(red: 0.8509803922, green: 0.5764705882, blue: 0.8235294118, alpha: 1)))
        case .sky:
            (Color(#colorLiteral(red: 0.3843137255, green: 0.7568627451, blue: 0.8980392157, alpha: 1)), Color(#colorLiteral(red: 0.6274509804, green: 0.8509803922, blue: 0.937254902, alpha: 1)))
        case .brown:
            (Color(#colorLiteral(red: 0.8117647059, green: 0.6, blue: 0.5254901961, alpha: 1)), Color(#colorLiteral(red: 0.8470588235, green: 0.6784313725, blue: 0.6196078431, alpha: 1)))
        case .gray:
            (Color(#colorLiteral(red: 0.5704585314, green: 0.5704723597, blue: 0.5704649091, alpha: 1)), Color(#colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)))
        case .colorPicker:
            (Color(#colorLiteral(red: 0.5490196078, green: 0.2941176471, blue: 0.3960784314, alpha: 1)), Color(#colorLiteral(red: 0.6745098039, green: 0.3960784314, blue: 0.568627451, alpha: 1)))
        case .coral:
            (Color(#colorLiteral(red: 0.9137254902, green: 0.5764705882, blue: 0.5411764706, alpha: 1)), Color(#colorLiteral(red: 0.9058823529, green: 0.6352941176, blue: 0.6078431373, alpha: 1)))
        case .bluePink:
            (Color(#colorLiteral(red: 0.4235294118, green: 0.5764705882, blue: 0.9960784314, alpha: 1)), Color(#colorLiteral(red: 0.7803921569, green: 0.3803921569, blue: 0.7568627451, alpha: 1)))
        case .oceanBlue:
            (Color(#colorLiteral(red: 0.1803921569, green: 0.1921568627, blue: 0.5725490196, alpha: 1)), Color(#colorLiteral(red: 0.1058823529, green: 1, blue: 1, alpha: 1)))
        case .antarctica:
            (Color(#colorLiteral(red: 0.1176470588, green: 0.6823529412, blue: 0.5960784314, alpha: 1)), Color(#colorLiteral(red: 0.8470588235, green: 0.7098039216, blue: 1, alpha: 1)))
        case .sweetMorning:
            (Color(#colorLiteral(red: 1, green: 0.3725490196, blue: 0.4274509804, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.7647058824, blue: 0.4431372549, alpha: 1)))
        case .lusciousLime:
            (Color(#colorLiteral(red: 0, green: 0.5725490196, blue: 0.2705882353, alpha: 1)), Color(#colorLiteral(red: 0.9882352941, green: 0.9333333333, blue: 0.1294117647, alpha: 1)))
        case .celestial:
            (Color(#colorLiteral(red: 0.7647058824, green: 0.2156862745, blue: 0.3921568627, alpha: 1)), Color(#colorLiteral(red: 0.1137254902, green: 0.1490196078, blue: 0.4431372549, alpha: 1)))
        case .yellowOrange:
            (Color(#colorLiteral(red: 0.9843838811, green: 0.2902515233, blue: 0.2274344563, alpha: 1)), Color(#colorLiteral(red: 0.9960982203, green: 0.8237271309, blue: 0.160815984, alpha: 1)))
        case .cloudBurst:
            (Color(#colorLiteral(red: 0.03529411765, green: 0.1254901961, blue: 0.2470588235, alpha: 1)), Color(#colorLiteral(red: 0.3254901961, green: 0.4705882353, blue: 0.5843137255, alpha: 1)))
        case .candy:
            (Color(#colorLiteral(red: 1, green: 0.7607843137, blue: 0.8431372549, alpha: 1)), Color(#colorLiteral(red: 0.7882352941, green: 0.8509803922, blue: 1, alpha: 1)))
        case .fitnessRed:
            (Color(#colorLiteral(red: 0.9961032271, green: 0.1450680494, blue: 0.1020308509, alpha: 1)), Color(#colorLiteral(red: 1, green: 0.1606997848, blue: 0.5649436116, alpha: 1)))
        case .fitnessGreen:
            (Color(#colorLiteral(red: 0.5688378811, green: 0.9726611972, blue: 0.0001379904279, alpha: 1)), Color(#colorLiteral(red: 0.8432601094, green: 1, blue: 0.0001792707626, alpha: 1)))
        case .fitnessBlue:
            (Color(#colorLiteral(red: 0, green: 0.8315491676, blue: 0.9331019521, alpha: 1)), Color(#colorLiteral(red: 0, green: 1, blue: 0.65869385, alpha: 1)))
        }
    }
    
    var lightColor: Color { colorPair.light }
    var darkColor: Color { colorPair.dark }
}
