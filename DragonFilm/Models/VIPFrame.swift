import Foundation

struct VIPFrame: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let imageName: String
    let description: String

    static let allFrames: [VIPFrame] = [
        VIPFrame(id: "frame_1", name: "Thần Long Cyber", imageName: "VIPFrame1", description: "Rồng máy công nghệ tương lai huyền ảo"),
        VIPFrame(id: "frame_2", name: "Nguyện Ước Tinh Tú", imageName: "VIPFrame2", description: "Hào quang vũ trụ lấp lánh"),
        VIPFrame(id: "frame_3", name: "Hào Quang Tinh Vân", imageName: "VIPFrame3", description: "Tinh hoa thiên hà kỳ diệu"),
        VIPFrame(id: "frame_4", name: "Hoàng Kim Đế Vương", imageName: "VIPFrame4", description: "Vàng kim quý tộc quyền uy"),
        VIPFrame(id: "frame_5", name: "Phượng Hoàng Lửa", imageName: "VIPFrame5", description: "Lửa phượng hoàng bất tử rực cháy"),
        VIPFrame(id: "frame_6", name: "Hacker Ma Trận", imageName: "VIPFrame6", description: "Ánh sáng Neon Cyberpunk huyền bí"),
        VIPFrame(id: "frame_7", name: "Vương Miện Hoàng Gia", imageName: "VIPFrame7", description: "Vương miện tôn quý tối thượng"),
        VIPFrame(id: "frame_8", name: "Pha Lê Dễ Thương", imageName: "VIPFrame8", description: "Pha lê hoạt hình ngọt ngào và năng động"),
        VIPFrame(id: "frame_9", name: "Vòng Tròn Cực Quang", imageName: "VIPFrame9", description: "Ánh sáng cực quang phương Bắc huyền diệu")
    ]
}
