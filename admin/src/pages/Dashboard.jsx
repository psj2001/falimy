import { useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '../api';

function formatDate(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString();
}

function formatDay(value) {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleDateString();
}

function initials(user) {
  const name = String(user?.fullName || user?.email || '?');
  return name
    .split(/[\s@]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}

function Avatar({ user, large = false }) {
  const photo = String(user?.photoPath || '');
  const remote = photo.startsWith('http://') || photo.startsWith('https://');
  return (
    <div className={large ? 'avatar-lg' : 'avatar'}>
      {remote ? <img src={photo} alt="" /> : initials(user)}
    </div>
  );
}

function occupationLabel(user) {
  if (!user?.occupationStatus) return '—';
  if (user.occupationStatus === 'working') {
    return user.companyName
      ? `Working · ${user.companyName}`
      : 'Working';
  }
  if (user.occupationStatus === 'studying') {
    return user.studyClassOrCourse
      ? `Studying · ${user.studyClassOrCourse}`
      : 'Studying';
  }
  return user.occupationStatus;
}

function locationParts(user) {
  const loc = user?.location;
  if (!loc) return [];
  return [loc.place, loc.state, loc.country].filter(Boolean);
}

function locationLabel(user) {
  const parts = locationParts(user);
  if (parts.length) return parts.join(', ');
  if (user?.location?.address) return user.location.address;
  if (user?.location?.latitude != null && user?.location?.longitude != null) {
    return `${Number(user.location.latitude).toFixed(4)}, ${Number(
      user.location.longitude,
    ).toFixed(4)}`;
  }
  return '—';
}

function mapsUrl(loc) {
  if (!loc || loc.latitude == null || loc.longitude == null) return null;
  return `https://www.google.com/maps?q=${loc.latitude},${loc.longitude}`;
}

function mapsEmbedUrl(loc) {
  if (!loc || loc.latitude == null || loc.longitude == null) return null;
  return `https://maps.google.com/maps?q=${loc.latitude},${loc.longitude}&z=15&output=embed`;
}

function Kv({ label, value }) {
  const text =
    value == null || value === ''
      ? '—'
      : typeof value === 'boolean'
        ? value
          ? 'Yes'
          : 'No'
        : String(value);
  return (
    <>
      <span>{label}</span>
      <strong>{text}</strong>
    </>
  );
}

function NotifyModal({
  open,
  onClose,
  selectedCount,
  sending,
  error,
  onSend,
}) {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [audience, setAudience] = useState('all');

  useEffect(() => {
    if (open) {
      setTitle('');
      setMessage('');
      setAudience(selectedCount ? 'selected' : 'all');
    }
  }, [open, selectedCount]);

  if (!open) return null;

  return (
    <div className="overlay modal-wrap" onClick={onClose}>
      <form
        className="modal"
        onClick={(event) => event.stopPropagation()}
        onSubmit={(event) => {
          event.preventDefault();
          onSend({ title, message, audience });
        }}
      >
        <div className="modal-head">
          <div>
            <h2 style={{ margin: 0 }}>Send app notification</h2>
            <p className="muted">
              Users will see this in the Falimy notifications inbox.
            </p>
          </div>
          <button type="button" className="ghost-btn" onClick={onClose}>
            Close
          </button>
        </div>
        {error ? <div className="error-banner">{error}</div> : null}
        <div className="audience">
          <button
            type="button"
            className={audience === 'all' ? 'primary-btn' : 'ghost-btn'}
            onClick={() => setAudience('all')}
          >
            All users
          </button>
          <button
            type="button"
            className={audience === 'selected' ? 'primary-btn' : 'ghost-btn'}
            onClick={() => setAudience('selected')}
            disabled={!selectedCount}
          >
            Selected ({selectedCount})
          </button>
        </div>
        <label className="field">
          <span>Title</span>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            maxLength={120}
            required
            placeholder="App update, reminder, announcement…"
          />
        </label>
        <label className="field">
          <span>Message</span>
          <textarea
            rows={5}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            maxLength={2000}
            required
            placeholder="Write the notification users will read in the app."
          />
        </label>
        <button className="primary-btn" type="submit" disabled={sending}>
          {sending ? 'Sending…' : 'Send notification'}
        </button>
      </form>
    </div>
  );
}

function UserDetail({
  detail,
  loading,
  error,
  onClose,
  onNotify,
  onDelete,
  deleting,
}) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const user = detail?.user;

  useEffect(() => {
    setConfirmDelete(false);
  }, [user?.id]);

  if (!detail && !loading && !error) return null;

  return (
    <div className="overlay" onClick={onClose}>
      <aside className="drawer" onClick={(event) => event.stopPropagation()}>
        <div className="drawer-head">
          <div>
            <h2 style={{ margin: 0 }}>User details</h2>
            <p className="muted">Full profile stored for this account.</p>
          </div>
          <button className="ghost-btn" type="button" onClick={onClose}>
            Close
          </button>
        </div>
        {error ? <div className="error-banner">{error}</div> : null}
        {loading && !user ? <p className="muted">Loading…</p> : null}
        {user ? (
          <>
            <div className="identity">
              <Avatar user={user} large />
              <div>
                <h2>{user.fullName || 'Unnamed user'}</h2>
                <div>{user.email}</div>
                <div className="muted">ID {user.id}</div>
              </div>
            </div>
            <div className="top-actions" style={{ marginBottom: 18 }}>
              <button className="primary-btn" type="button" onClick={onNotify}>
                Notify this user
              </button>
              <button
                className="danger-btn"
                type="button"
                onClick={() => setConfirmDelete(true)}
                disabled={deleting}
              >
                Delete user
              </button>
            </div>
            {confirmDelete ? (
              <div className="confirm-box">
                <strong>Delete {user.fullName || user.email}?</strong>
                <p className="muted">
                  This removes their account, family links, and synced app
                  data. It cannot be undone.
                </p>
                <div className="top-actions">
                  <button
                    className="ghost-btn"
                    type="button"
                    onClick={() => setConfirmDelete(false)}
                    disabled={deleting}
                  >
                    Cancel
                  </button>
                  <button
                    className="danger-btn"
                    type="button"
                    onClick={() => onDelete(user)}
                    disabled={deleting}
                  >
                    {deleting ? 'Deleting…' : 'Yes, delete'}
                  </button>
                </div>
              </div>
            ) : null}

            <section className="section">
              <h3>Location</h3>
              <div className="kv">
                <Kv label="Country" value={user.location?.country} />
                <Kv label="State" value={user.location?.state} />
                <Kv label="Place" value={user.location?.place} />
                <Kv label="Address" value={user.location?.address} />
                <Kv
                  label="Exact"
                  value={
                    user.location?.latitude != null &&
                    user.location?.longitude != null
                      ? `${Number(user.location.latitude).toFixed(6)}, ${Number(
                          user.location.longitude,
                        ).toFixed(6)}`
                      : null
                  }
                />
                <Kv
                  label="Source"
                  value={
                    user.location?.source === 'gps'
                      ? 'GPS (exact)'
                      : user.location?.source === 'ip'
                        ? 'IP (approximate)'
                        : null
                  }
                />
                <Kv
                  label="Captured"
                  value={formatDate(user.location?.capturedAt)}
                />
              </div>
              {mapsEmbedUrl(user.location) ? (
                <div className="map-wrap">
                  <iframe
                    title="User location"
                    src={mapsEmbedUrl(user.location)}
                    loading="lazy"
                  />
                  <a
                    className="map-link"
                    href={mapsUrl(user.location)}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Open exact location in Google Maps
                  </a>
                </div>
              ) : (
                <p className="muted">No map pin stored for this user yet.</p>
              )}
            </section>

            <section className="section">
              <h3>Account</h3>
              <div className="kv">
                <Kv label="Joined" value={formatDate(user.createdAt)} />
                <Kv label="Updated" value={formatDate(user.updatedAt)} />
                <Kv
                  label="Onboarded"
                  value={user.onboardingComplete ? 'Yes' : 'No'}
                />
                <Kv label="Date of birth" value={formatDay(user.dateOfBirth)} />
                <Kv label="Family name" value={user.familyName} />
              </div>
            </section>

            <section className="section">
              <h3>Occupation</h3>
              <div className="kv">
                <Kv label="Status" value={user.occupationStatus} />
                <Kv label="Company" value={user.companyName} />
                <Kv
                  label="Salary"
                  value={user.salary == null ? null : user.salary}
                />
                <Kv label="Study" value={user.studyClassOrCourse} />
              </div>
            </section>

            <section className="section">
              <h3>Family</h3>
              <div className="kv">
                <Kv label="Father" value={user.fatherName} />
                <Kv label="Mother" value={user.motherName} />
                <Kv label="Married" value={user.isMarried} />
                <Kv label="Spouse" value={user.spouse?.name} />
                <Kv label="Spouse profession" value={user.spouse?.profession} />
                <Kv label="Spouse age" value={user.spouse?.age || null} />
                <Kv
                  label="Spouse family"
                  value={user.spouse?.familyName}
                />
                <Kv label="Has children" value={user.hasChildren} />
              </div>
              {user.siblings?.length ? (
                <div className="chips" style={{ marginTop: 10 }}>
                  {user.siblings.map((sibling, index) => (
                    <span className="chip" key={`${sibling.name}-${index}`}>
                      {sibling.seniority} {sibling.gender}: {sibling.name || '—'}
                    </span>
                  ))}
                </div>
              ) : null}
              {user.children?.length ? (
                <div className="chips" style={{ marginTop: 10 }}>
                  {user.children.map((child, index) => (
                    <span className="chip" key={`${child.name}-${index}`}>
                      Child: {child.name || '—'}
                      {child.age ? ` · ${child.age}` : ''}
                    </span>
                  ))}
                </div>
              ) : null}
            </section>

            <section className="section">
              <h3>Linked members</h3>
              {Object.keys(user.memberLinks || {}).length === 0 ? (
                <p className="muted">No linked app users yet.</p>
              ) : (
                Object.entries(user.memberLinks).map(([key, link]) => (
                  <div className="list-card" key={key}>
                    <strong>
                      {link.role || key}: {link.name || '—'}
                    </strong>
                    <div className="muted">
                      {link.email || 'No email'} · {link.kind || key}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Linked from invites</h3>
              {(user.linkedFromInvites || []).length === 0 ? (
                <p className="muted">Not joined through an invite.</p>
              ) : (
                user.linkedFromInvites.map((link) => (
                  <div className="list-card" key={link.inviteId || link.memberKey}>
                    <strong>
                      {link.memberRole} in {link.inviterName || 'family'} tree
                    </strong>
                    <div className="muted">
                      {link.familyName || 'No family name'} · invite {link.inviteId}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Invites sent ({detail.invitesSent?.length || 0})</h3>
              {(detail.invitesSent || []).length === 0 ? (
                <p className="muted">None</p>
              ) : (
                detail.invitesSent.map((invite) => (
                  <div className="list-card" key={invite.id}>
                    <strong>
                      {invite.memberName} · {invite.memberRole}
                    </strong>
                    <div className="muted">
                      {invite.inviteeEmail} · {invite.status}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Assets ({detail.assets?.length || 0})</h3>
              {(detail.assets || []).length === 0 ? (
                <p className="muted">None synced</p>
              ) : (
                detail.assets.map((item) => (
                  <div className="list-card" key={item.id}>
                    <strong>
                      {item.asset?.title ||
                        item.asset?.name ||
                        item.asset?.type ||
                        'Asset'}
                    </strong>
                    <div className="muted">
                      {item.asset?.category || item.assetId}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Reminders ({detail.reminders?.length || 0})</h3>
              {(detail.reminders || []).length === 0 ? (
                <p className="muted">None synced</p>
              ) : (
                detail.reminders.map((item) => (
                  <div className="list-card" key={item.id}>
                    <strong>
                      {item.reminder?.title || item.reminderId}
                    </strong>
                    <div className="muted">
                      {item.reminder?.amount
                        ? `Amount ${item.reminder.amount}`
                        : 'Payment reminder'}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Cash books ({detail.books?.length || 0})</h3>
              {(detail.books || []).length === 0 ? (
                <p className="muted">None synced</p>
              ) : (
                detail.books.map((item) => (
                  <div className="list-card" key={item.id}>
                    <strong>
                      {item.book?.name || item.book?.title || item.bookId}
                    </strong>
                    <div className="muted">
                      {item.entryCount} entries · synced {formatDate(item.syncedAt)}
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Budgets ({detail.budgets?.length || 0})</h3>
              {(detail.budgets || []).length === 0 ? (
                <p className="muted">None synced</p>
              ) : (
                detail.budgets.map((item) => (
                  <div className="list-card" key={item.id}>
                    <strong>{item.month}</strong>
                    <div className="muted">
                      {item.currency} · savings {item.savingsTargetPercent}%
                    </div>
                  </div>
                ))
              )}
            </section>

            <section className="section">
              <h3>Recent notifications</h3>
              {(detail.notifications || []).length === 0 ? (
                <p className="muted">None</p>
              ) : (
                detail.notifications.map((item) => (
                  <div className="list-card" key={item.id}>
                    <strong>{item.title}</strong>
                    <div>{item.message}</div>
                    <div className="muted">
                      {item.type} · {formatDate(item.createdAt)}
                      {item.isRead ? ' · read' : ' · unread'}
                    </div>
                  </div>
                ))
              )}
            </section>
          </>
        ) : null}
      </aside>
    </div>
  );
}

export default function Dashboard({ session, onLogout, onExpired }) {
  const [tab, setTab] = useState('users');
  const [query, setQuery] = useState('');
  const [users, setUsers] = useState([]);
  const [stats, setStats] = useState({
    total: 0,
    matched: 0,
    onboarded: 0,
    married: 0,
  });
  const [selected, setSelected] = useState(() => new Set());
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [detail, setDetail] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState('');
  const [openUserId, setOpenUserId] = useState(null);
  const [notifyOpen, setNotifyOpen] = useState(false);
  const [notifyTargetIds, setNotifyTargetIds] = useState(null);
  const [sending, setSending] = useState(false);
  const [notifyError, setNotifyError] = useState('');
  const [broadcasts, setBroadcasts] = useState([]);
  const [deleting, setDeleting] = useState(false);

  const call = useCallback(
    async (path, options = {}) => {
      try {
        return await api(path, { ...options, token: session.token });
      } catch (err) {
        if (err.status === 401 || err.status === 403) {
          onExpired();
        }
        throw err;
      }
    },
    [onExpired, session.token],
  );

  const loadUsers = useCallback(
    async (q = query) => {
      setLoading(true);
      setError('');
      try {
        const data = await call(
          `/api/admin/users${q ? `?q=${encodeURIComponent(q)}` : ''}`,
        );
        setUsers(data.users || []);
        if (data.stats) setStats(data.stats);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    },
    [call, query],
  );

  const loadBroadcasts = useCallback(async () => {
    try {
      const data = await call('/api/admin/notifications/recent');
      setBroadcasts(data.broadcasts || []);
    } catch {
      setBroadcasts([]);
    }
  }, [call]);

  useEffect(() => {
    loadBroadcasts();
  }, [loadBroadcasts]);

  useEffect(() => {
    const timer = setTimeout(() => loadUsers(query), query ? 250 : 0);
    return () => clearTimeout(timer);
  }, [query, loadUsers]);

  async function openUser(user) {
    setOpenUserId(user.id);
    setDetail(null);
    setDetailLoading(true);
    setDetailError('');
    try {
      const data = await call(`/api/admin/users/${user.id}`);
      setDetail(data);
    } catch (err) {
      setDetail(null);
      setDetailError(err.message);
    } finally {
      setDetailLoading(false);
    }
  }

  function toggleSelected(id, checked) {
    setSelected((current) => {
      const next = new Set(current);
      if (checked) next.add(id);
      else next.delete(id);
      return next;
    });
  }

  function toggleAll(checked) {
    setSelected(checked ? new Set(users.map((user) => user.id)) : new Set());
  }

  async function sendNotification({ title, message, audience }) {
    setSending(true);
    setNotifyError('');
    try {
      const userIds =
        audience === 'selected'
          ? notifyTargetIds || Array.from(selected)
          : [];
      if (audience === 'selected' && !userIds.length) {
        throw new Error('Select at least one user');
      }
      const result = await call('/api/admin/notifications', {
        method: 'POST',
        body: { title, message, userIds },
      });
      setNotifyOpen(false);
      setNotifyTargetIds(null);
      setNotice(
        `Sent “${result.title}” to ${result.recipientCount} user${
          result.recipientCount === 1 ? '' : 's'
        }.`,
      );
      await loadBroadcasts();
    } catch (err) {
      setNotifyError(err.message);
    } finally {
      setSending(false);
    }
  }

  async function deleteUser(user) {
    if (!user?.id) return;
    setDeleting(true);
    setError('');
    try {
      await call(`/api/admin/users/${user.id}`, { method: 'DELETE' });
      setNotice(`Deleted ${user.fullName || user.email}.`);
      setOpenUserId(null);
      setDetail(null);
      setDetailError('');
      setSelected((current) => {
        const next = new Set(current);
        next.delete(user.id);
        return next;
      });
      await loadUsers(query);
    } catch (err) {
      setDetailError(err.message);
      setError(err.message);
    } finally {
      setDeleting(false);
    }
  }

  const allChecked = useMemo(
    () => users.length > 0 && users.every((user) => selected.has(user.id)),
    [selected, users],
  );

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand-mark">
          <div className="brand-dot">F</div>
          <b>Falimy</b>
        </div>
        <button
          className={`nav-btn ${tab === 'users' ? 'active' : ''}`}
          onClick={() => setTab('users')}
        >
          Users
        </button>
        <button
          className={`nav-btn ${tab === 'notifications' ? 'active' : ''}`}
          onClick={() => setTab('notifications')}
        >
          Notifications
        </button>
        <div className="sidebar-foot">
          <div>{session.admin?.email}</div>
          <button
            className="ghost-btn"
            style={{ marginTop: 12, width: '100%' }}
            onClick={onLogout}
          >
            Sign out
          </button>
        </div>
      </aside>

      <main className="main">
        <div className="topbar">
          <div>
            <h1>{tab === 'users' ? 'All users' : 'App notifications'}</h1>
            <p>
              {tab === 'users'
                ? 'Open any row to see the full account, family, and synced app data.'
                : 'Broadcast a message to the Falimy in-app inbox.'}
            </p>
          </div>
          <div className="top-actions">
            <button
              className="primary-btn"
              onClick={() => {
                setNotifyTargetIds(null);
                setNotifyError('');
                setNotifyOpen(true);
              }}
            >
              Send notification
            </button>
          </div>
        </div>

        {error ? <div className="error-banner">{error}</div> : null}
        {notice ? <div className="success-banner">{notice}</div> : null}

        {tab === 'users' ? (
          <>
            <div className="stats">
              <div className="stat-card">
                <span>Total users</span>
                <strong>{stats.total}</strong>
              </div>
              <div className="stat-card">
                <span>Showing</span>
                <strong>{stats.matched}</strong>
              </div>
              <div className="stat-card">
                <span>Onboarded</span>
                <strong>{stats.onboarded}</strong>
              </div>
              <div className="stat-card">
                <span>Married</span>
                <strong>{stats.married}</strong>
              </div>
            </div>

            <div className="toolbar">
              <input
                className="search"
                placeholder="Search name, email, family, location…"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
              <button
                className="ghost-btn"
                disabled={!selected.size}
                onClick={() => {
                  setNotifyTargetIds(Array.from(selected));
                  setNotifyError('');
                  setNotifyOpen(true);
                }}
              >
                Notify selected ({selected.size})
              </button>
            </div>

            <div className="panel table-wrap">
              {loading && !users.length ? (
                <div className="empty">Loading users…</div>
              ) : users.length === 0 ? (
                <div className="empty">No users found.</div>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th>
                        <input
                          type="checkbox"
                          checked={allChecked}
                          onChange={(e) => toggleAll(e.target.checked)}
                        />
                      </th>
                      <th>User</th>
                      <th>Family</th>
                      <th>Occupation</th>
                      <th>Location</th>
                      <th>Onboarded</th>
                      <th>Joined</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user) => (
                      <tr
                        key={user.id}
                        className={openUserId === user.id ? 'selected' : ''}
                        onClick={() => openUser(user)}
                      >
                        <td onClick={(event) => event.stopPropagation()}>
                          <input
                            type="checkbox"
                            checked={selected.has(user.id)}
                            onChange={(e) =>
                              toggleSelected(user.id, e.target.checked)
                            }
                          />
                        </td>
                        <td>
                          <div className="name-cell">
                            <Avatar user={user} />
                            <div>
                              <strong>{user.fullName || 'Unnamed user'}</strong>
                              <div className="muted">{user.email}</div>
                            </div>
                          </div>
                        </td>
                        <td>
                          <div>{user.familyName || '—'}</div>
                          <div className="muted">
                            {user.fatherName || user.motherName
                              ? [user.fatherName, user.motherName]
                                  .filter(Boolean)
                                  .join(' · ')
                              : 'No parents listed'}
                          </div>
                        </td>
                        <td>{occupationLabel(user)}</td>
                        <td>
                          <div>{locationLabel(user)}</div>
                          {user.location?.source ? (
                            <div className="muted">
                              {user.location.source === 'gps'
                                ? 'Exact GPS'
                                : 'Approximate'}
                            </div>
                          ) : null}
                        </td>
                        <td>
                          <span
                            className={`badge ${
                              user.onboardingComplete ? 'on' : 'off'
                            }`}
                          >
                            {user.onboardingComplete ? 'Yes' : 'No'}
                          </span>
                        </td>
                        <td>{formatDay(user.createdAt)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </>
        ) : (
          <div className="panel" style={{ padding: 18 }}>
            <div className="top-actions" style={{ marginBottom: 16 }}>
              <button
                className="primary-btn"
                onClick={() => {
                  setNotifyTargetIds(null);
                  setNotifyError('');
                  setNotifyOpen(true);
                }}
              >
                New notification
              </button>
            </div>
            {broadcasts.length === 0 ? (
              <div className="empty">No admin notifications sent yet.</div>
            ) : (
              broadcasts.map((item) => (
                <div className="list-card" key={item.id || item.createdAt}>
                  <strong>{item.title}</strong>
                  <div>{item.message}</div>
                  <div className="muted">
                    {item.recipientCount} recipient
                    {item.recipientCount === 1 ? '' : 's'} ·{' '}
                    {formatDate(item.createdAt)}
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </main>

      <UserDetail
        detail={openUserId ? detail : null}
        loading={detailLoading}
        error={detailError}
        deleting={deleting}
        onClose={() => {
          setOpenUserId(null);
          setDetail(null);
          setDetailError('');
        }}
        onNotify={() => {
          if (!openUserId) return;
          setNotifyTargetIds([openUserId]);
          setNotifyError('');
          setNotifyOpen(true);
        }}
        onDelete={deleteUser}
      />

      <NotifyModal
        open={notifyOpen}
        onClose={() => {
          setNotifyOpen(false);
          setNotifyTargetIds(null);
        }}
        selectedCount={(notifyTargetIds || Array.from(selected)).length}
        sending={sending}
        error={notifyError}
        onSend={sendNotification}
      />
    </div>
  );
}
