const mongoose = require('mongoose');

const siblingSchema = new mongoose.Schema(
  {
    name: { type: String, default: '' },
    gender: { type: String, enum: ['male', 'female'], default: 'male' },
    seniority: { type: String, enum: ['elder', 'younger'], default: 'younger' },
  },
  { _id: false },
);

const spouseSchema = new mongoose.Schema(
  {
    name: { type: String, default: '' },
    profession: { type: String, default: '' },
    age: { type: Number, default: 0 },
    familyName: { type: String, default: '' },
  },
  { _id: false },
);

const childSchema = new mongoose.Schema(
  {
    name: { type: String, default: '' },
    age: { type: Number, default: 0 },
  },
  { _id: false },
);

const memberLinkSchema = new mongoose.Schema(
  {
    userId: String,
    email: String,
    name: String,
    kind: String,
    role: String,
    linkedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const linkedInviteSchema = new mongoose.Schema(
  {
    inviteId: String,
    inviterUserId: String,
    inviterName: String,
    memberKey: String,
    memberName: String,
    memberKind: String,
    memberRole: String,
    familyName: String,
    spouseSuggestionName: String,
    spouseSuggestionRole: String,
  },
  { _id: false },
);

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },

    // Family profile
    fullName: String,
    dateOfBirth: Date,
    familyName: String,
    photoPath: String,
    fatherName: String,
    motherName: String,
    siblings: { type: [siblingSchema], default: [] },
    isMarried: Boolean,
    spouse: spouseSchema,
    hasChildren: Boolean,
    children: { type: [childSchema], default: [] },
    onboardingComplete: { type: Boolean, default: false },

    occupationStatus: {
      type: String,
      enum: ['working', 'studying', 'unemployed', 'retired'],
    },
    companyName: String,
    salary: Number,
    studyClassOrCourse: String,

    memberLinks: { type: Map, of: memberLinkSchema, default: {} },
    linkedFromInvites: { type: [linkedInviteSchema], default: [] },
  },
  { timestamps: true },
);

userSchema.methods.toPublic = function toPublic() {
  return {
    id: this._id.toString(),
    email: this.email,
  };
};

userSchema.methods.toProfile = function toProfile() {
  const memberLinks = {};
  if (this.memberLinks) {
    for (const [key, value] of this.memberLinks.entries()) {
      memberLinks[key] =
        value && typeof value.toObject === 'function'
          ? value.toObject()
          : value;
    }
  }

  return {
    fullName: this.fullName ?? null,
    dateOfBirth: this.dateOfBirth ?? null,
    familyName: this.familyName ?? null,
    photoPath: this.photoPath ?? null,
    fatherName: this.fatherName ?? null,
    motherName: this.motherName ?? null,
    siblings: this.siblings ?? [],
    isMarried: this.isMarried ?? null,
    spouse: this.spouse ?? null,
    hasChildren: this.hasChildren ?? null,
    children: this.children ?? [],
    onboardingComplete: this.onboardingComplete ?? false,
    occupationStatus: this.occupationStatus ?? null,
    companyName: this.companyName ?? null,
    salary: this.salary ?? null,
    studyClassOrCourse: this.studyClassOrCourse ?? null,
    memberLinks,
    linkedFromInvites: this.linkedFromInvites ?? [],
  };
};

module.exports = mongoose.model('User', userSchema);
