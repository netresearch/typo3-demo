-- Netresearch Extensions Demo Pages
-- Imported on first boot to showcase Netresearch TYPO3 extensions

-- Parent page: "Extensions" in main navigation
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, is_siteroot, backend_layout, sorting, hidden, deleted)
VALUES (101, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Extensions', '/extensions', 1, 0, '', 525, 0, 0);

-- =============================================================================
-- RTE CKEditor Image (frontend visible)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (102, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'RTE CKEditor Image', '/extensions/rte-ckeditor-image', 1, 100, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (400, 102, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'RTE CKEditor Image',
'<p>Advanced image handling for CKEditor 5 in TYPO3. This extension adds block images, inline images, click-to-enlarge, and linked images directly in the rich text editor.</p>

<h2>Block Image</h2>
<p>A standalone image inserted via CKEditor — rendered as a processed TYPO3 image with responsive srcset:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7354.jpg" alt="Team photo demo" width="800" data-htmlarea-file-uid="190" data-htmlarea-file-table="sys_file"></p>

<h2>Click-to-Enlarge (Lightbox)</h2>
<p>Adding <code>data-htmlarea-zoom=\"true\"</code> enables lightbox on click:</p>
<p><img src="/fileadmin/user_upload/images/Home/CH5_7203.jpg" alt="Click to enlarge demo" width="400" data-htmlarea-file-uid="188" data-htmlarea-file-table="sys_file" data-htmlarea-zoom="true"></p>
<p><em>Click the image above to see the lightbox popup.</em></p>

<h2>Inline Image in Text</h2>
<p>Text can contain inline images like this <img class="image image-inline" src="/fileadmin/user_upload/images/netresearch-typo3-demo.png" alt="inline logo" width="60" data-htmlarea-file-uid="1" data-htmlarea-file-table="sys_file"> logo that flows naturally within the paragraph.</p>

<h2>Features</h2>
<ul>
<li><strong>Block images</strong> with captions and alignment (left, center, right)</li>
<li><strong>Inline images</strong> that flow with text content</li>
<li><strong>Click-to-enlarge</strong> via lightbox (<code>data-htmlarea-zoom=\"true\"</code>)</li>
<li><strong>Linked images</strong> wrapping images in hyperlinks to pages or URLs</li>
<li><strong>Image alignment matrix</strong> — all combinations of alignment and caption</li>
</ul>
<p>Edit this page in the TYPO3 backend to see the CKEditor image toolbar button in action.</p>
<p><a href="https://github.com/netresearch/t3x-rte_ckeditor_image" target="_blank" rel="noopener">GitHub: netresearch/t3x-rte_ckeditor_image</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Cowriter (backend CKEditor plugin)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (103, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'AI Cowriter', '/extensions/cowriter', 1, 200, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (401, 103, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'AI Cowriter',
'<p>AI-powered content assistant integrated directly into CKEditor. Select text and use AI to:</p>
<ul>
<li><strong>Rewrite</strong> text in a different tone or style</li>
<li><strong>Summarize</strong> long content into concise versions</li>
<li><strong>Extend</strong> short text with additional detail</li>
<li><strong>Fix grammar</strong> and spelling</li>
<li><strong>Translate</strong> between languages</li>
<li><strong>Custom tasks</strong> with configurable prompts</li>
</ul>
<p>Requires an LLM provider configured in the NR LLM backend module. Edit this page in the backend to try the Cowriter button in the CKEditor toolbar.</p>
<p><a href="https://github.com/netresearch/t3x-cowriter" target="_blank" rel="noopener">GitHub: netresearch/t3x-cowriter</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- NR LLM (backend module)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (104, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'LLM Foundation', '/extensions/nr-llm', 1, 300, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (402, 104, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'NR LLM — AI Foundation for TYPO3',
'<p>The shared AI foundation for TYPO3. One LLM setup for every extension on your site. Provides:</p>
<ul>
<li><strong>Provider management</strong> — configure Ollama, OpenAI, Anthropic, or custom endpoints</li>
<li><strong>Model registry</strong> — manage available models with temperature/token settings</li>
<li><strong>Task system</strong> — reusable prompt templates across extensions</li>
<li><strong>Configuration profiles</strong> — different settings for different use cases (creative, analytical, etc.)</li>
<li><strong>Backend module</strong> — visual management of all LLM resources</li>
</ul>
<p>Used by Cowriter and Landing Page extensions. Configure providers in the TYPO3 backend under Admin Tools &gt; LLM.</p>
<p><a href="https://github.com/netresearch/t3x-nr-llm" target="_blank" rel="noopener">GitHub: netresearch/t3x-nr-llm</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Landing Page Generator (backend wizard)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (105, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Landing Page Generator', '/extensions/landing-page', 1, 400, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (403, 105, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'AI Landing Page Generator',
'<p>Generate complete landing pages using AI. The backend wizard creates structured TYPO3 pages with:</p>
<ul>
<li><strong>Hero sections</strong> with headlines and call-to-action</li>
<li><strong>Feature grids</strong> highlighting key benefits</li>
<li><strong>Content sections</strong> with text and images</li>
<li><strong>Contact forms</strong> for lead generation</li>
</ul>
<p>Requires NR LLM with a configured provider. Access the wizard in the TYPO3 backend under Web &gt; Landing Pages.</p>
<p><a href="https://github.com/netresearch/nr-landingpage" target="_blank" rel="noopener">GitHub: netresearch/nr-landingpage</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Backend (backend authentication)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (106, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Backend)', '/extensions/passkeys-be', 1, 500, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (404, 106, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Passwordless Backend Login with Passkeys',
'<p>WebAuthn/FIDO2 Passkey authentication for the TYPO3 backend. Features:</p>
<ul>
<li><strong>Passwordless login</strong> using biometric authentication (fingerprint, face recognition)</li>
<li><strong>Per-group enforcement</strong> with four levels: Off, Encourage, Required, Enforced</li>
<li><strong>Multi-device support</strong> — register multiple passkeys per user</li>
<li><strong>Adoption dashboard</strong> — track passkey rollout across backend users</li>
<li><strong>Interstitial prompts</strong> — encourage or require passkey setup on login</li>
</ul>
<p>Manage passkeys in the TYPO3 backend under User Settings &gt; Passkeys. Administrators configure enforcement in backend user group settings.</p>
<p><a href="https://github.com/netresearch/t3x-nr-passkeys-be" target="_blank" rel="noopener">GitHub: netresearch/t3x-nr-passkeys-be</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Passkeys Frontend (frontend authentication)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (109, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Passkeys (Frontend)', '/extensions/passkeys-fe', 1, 510, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (407, 109, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Passkey-First Frontend Authentication',
'<p>WebAuthn/FIDO2 Passkey authentication for TYPO3 frontend users (fe_users). Features:</p>
<ul>
<li><strong>Passkey-first login</strong> — frontend users authenticate with biometrics instead of passwords</li>
<li><strong>Passkey registration</strong> — users register passkeys via their frontend profile</li>
<li><strong>Conditional UI</strong> — browser autofill integration for seamless passkey discovery</li>
<li><strong>Fallback to password</strong> — graceful degradation when passkeys are unavailable</li>
<li><strong>Multi-device support</strong> — users can register passkeys on multiple devices</li>
</ul>
<p>Integrates with felogin. Users manage their passkeys via a frontend plugin. Try the <a href="/login">Login page</a> to see the passkey login in action.</p>
<p><a href="https://github.com/netresearch/t3x-nr-passkeys-fe" target="_blank" rel="noopener">GitHub: netresearch/t3x-nr-passkeys-fe</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Vault (backend CLI + API)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (107, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Secrets Vault', '/extensions/vault', 1, 600, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (405, 107, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'NR Vault — Secure Secrets Management',
'<p>Enterprise-grade secrets management for TYPO3 with envelope encryption, access control, and audit logging.</p>
<ul>
<li><strong>Envelope encryption</strong> — secrets encrypted with per-secret data keys, wrapped by a master key</li>
<li><strong>CLI commands</strong> — <code>vault:init</code>, <code>vault:store</code>, <code>vault:retrieve</code>, <code>vault:rotate</code></li>
<li><strong>Access control</strong> — scope secrets to extensions, backend user groups, or environments</li>
<li><strong>Audit logging</strong> — track who accessed which secret and when</li>
<li><strong>Key rotation</strong> — rotate master keys without re-encrypting all secrets</li>
</ul>
<p>Initialize with <code>vendor/bin/typo3 vault:init</code>. Manage secrets via CLI or the TYPO3 backend module.</p>
<p><a href="https://github.com/netresearch/t3x-nr-vault" target="_blank" rel="noopener">GitHub: netresearch/t3x-nr-vault</a></p>',
0, 100, 0, 0);

-- =============================================================================
-- Temporal Cache (backend module + frontend behavior)
-- =============================================================================
INSERT IGNORE INTO pages (uid, pid, tstamp, crdate, title, slug, doktype, sorting, hidden, deleted)
VALUES (108, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'Temporal Cache', '/extensions/temporal-cache', 1, 700, 0, 0);

INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (406, 108, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Automatic Cache Invalidation for Timed Content',
'<p>Solves TYPO3 Forge Issue #14277: content with start/end times stays cached beyond its visibility window. This extension provides:</p>
<ul>
<li><strong>Automatic invalidation</strong> — cache clears when content becomes visible or expires</li>
<li><strong>Flexible scoping</strong> — invalidate single pages, page trees, or all pages</li>
<li><strong>Timing strategies</strong> — scheduler-based or on-demand cache clearing</li>
<li><strong>Backend module</strong> — overview of content with temporal scheduling</li>
</ul>
<p>Works transparently with all content types that use TYPO3 starttime/endtime fields. No configuration needed for basic usage.</p>
<p><a href="https://github.com/netresearch/t3x-nr-temporal-cache" target="_blank" rel="noopener">GitHub: netresearch/t3x-nr-temporal-cache</a></p>',
0, 100, 0, 0);
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (410, 101, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Netresearch TYPO3 Extensions',
'<p>This demo site showcases Netresearch open-source TYPO3 extensions, all compatible with TYPO3 v14.</p>

<h2>Content &amp; Editing</h2>
<ul>
<li><a href="/extensions/rte-ckeditor-image/">RTE CKEditor Image</a> — Block images, inline images, click-to-enlarge, and linked images directly in the rich text editor</li>
<li><a href="/extensions/cowriter/">AI Cowriter</a> — AI-powered content rewriting, summarizing, translating, and grammar fixing in CKEditor</li>
<li><a href="/extensions/landing-page/">Landing Page Generator</a> — Create complete landing pages using AI via a backend wizard</li>
</ul>

<h2>AI Foundation</h2>
<ul>
<li><a href="/extensions/nr-llm/">NR LLM</a> — Shared AI foundation for TYPO3. One LLM setup for every extension on your site (providers, models, tasks)</li>
</ul>

<h2>Security &amp; Authentication</h2>
<ul>
<li><a href="/extensions/passkeys-be/">Passkeys Backend</a> — Passwordless WebAuthn/FIDO2 authentication for backend users</li>
<li><a href="/extensions/passkeys-fe/">Passkeys Frontend</a> — Passkey-first authentication for frontend users (fe_users)</li>
<li><a href="/extensions/vault/">Secrets Vault</a> — Envelope encryption, access control, and audit logging for secrets management</li>
</ul>

<h2>Performance</h2>
<ul>
<li><a href="/extensions/temporal-cache/">Temporal Cache</a> — Automatic cache invalidation for content with start/end times</li>
</ul>

<p>All extensions are open source and available on <a href="https://github.com/netresearch" target="_blank" rel="noopener">GitHub</a>.</p>',
0, 100, 0, 0);

-- Demo frontend user for passkey testing (username: demo, password: demo)
INSERT IGNORE INTO fe_users (uid, pid, tstamp, crdate, username, password, usergroup, name, email, disable, deleted)
VALUES (2, 2, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'demo', '$argon2i$v=19$m=65536,t=4,p=1$L2kzRUEvbEdCbk5mWlViNA$2E5UgTQxfndqZIrMAKJHjuJvB9tQphrK/yCGsX7UQao', '1', 'Demo User', 'demo@example.com', 0, 0);

-- Demo credentials hint on login page
INSERT IGNORE INTO tt_content (uid, pid, tstamp, crdate, CType, header, bodytext, colPos, sorting, hidden, deleted)
VALUES (440, 93, UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), 'text', 'Try the Demo Login',
'<div class="alert alert-info">
<p><strong>Demo credentials:</strong></p>
<p>Username: <code>demo</code><br>Password: <code>demo</code></p>
<p>After logging in, you can register a Passkey under your account settings and use it for future logins — try the <strong>Passkey</strong> tab below!</p>
</div>',
0, 100, 0, 0);
