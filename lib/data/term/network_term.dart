class ApiConstants {
  //authetication
  static const loginUrl = '/login';
  static const validateOtpUrl = '/register/validate-otp';
  static const generateOtpUrl = '/register/generate-otp';
  //user-controller
  static const updateUserInforUrl = '/user';
  static const upLoadAvatarUrl = '/uploadAvatar';
  static const changePasswordUrl = '/changePassword';
  static const searchUserUrl = '/users/search/v2';
  static const userUrl = '/users/me/v2';
  static const allUserUrl = '/me';
  //friend-ship
  //study
  //vocabulary
  // static const
  // static const
  // static const
  static const allVocabulary = '/vocabularies/all/v2';
  static const vocabularyByTopic = '/vocabularies/limits-topic/v2';
  static const searchVocabulary = "/vocabularies/get-by-content/v2";
  static const searchVocabularyInTopic = "/vocabularies/search/v2";
  //static const
  //topic
  static const allTopicUrl = '/topics/all';
  static const searchTopicUrl = '/topics/search/v2';
  static const deleteTopicUrl = '/topics/';
  static const topicByClassroom = "/topics/all-common/";
  //question
  static const getQuestionUrl = '/questions/';
  static const getAllQuestion = '/questions/all';
  static const getQuestionByClassroomId = '/questions/limits-classRoom/v2';
  //friend
  static const addFriendUrl = '/friend-ship/add-friend';
  static const acceptFriendUrl = '/friend-ship/accept-friend';
  static const getSendingListFriendUrl = '/friend-ship/sending-list';
  static const getRequestListFriendUrl = '/friend-ship/request-list';
  static const getlistFriendUrl = '/friend-ship/friend-list';
  static const canelFriendUrl = '/friend-ship/cancel-friend';
  //chat
  static const getListConversationUrl = '/conversations/all-me';
  static const createConversationUrl = '/conversations';
  static const sendMessageUrl = '/messages';
  //classroom
  static const getAllClassroom = "/classrooms/all";
  //upload
  static const getUrlLink = "/api/upload";
  static const listHistoryCollectData = "/data-collection/all-me";
  static const createUpload = "/data-collection";
  
  //search
  static const searchVocabularyByText = "/vocabularies/all";

  static const searchVocabularyV2 = "/vocabularies/search";
  //
  static const aiCheckDataCollect =
      "https://wetalk.ibme.edu.vn/emg-label-tool/ai/detection";
}
